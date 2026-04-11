#!/usr/bin/env python3
import re
import json
import os
import requests
import sys
import time
import hashlib
from typing import Dict, List, Optional, Tuple, Any

# Get GitHub proxy from environment variable, default to empty string
def fetch_url_content(url: str) -> Optional[str]:
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        return resp.text
    except Exception as e:
        print(f"Failed to fetch {url} failed: {e}")
        return None

def resolve_final_url(url: str) -> Optional[str]:
    try:
        resp = requests.head(url, timeout=10, allow_redirects=True)
        return resp.url
    except Exception as e:
        print(f"Failed to resolve redirect URL: {e}")
        return None

def extract_download_url(html: str, patterns: List[str]) -> Optional[str]:
    for pattern in patterns:
        match = re.search(pattern, html)
        if match:
            url = match.group(1)
            if pattern == r'href="(https://[^"]+\.deb)"' and 'x86' not in url and 'amd64' not in url:
                continue
            return url
    return None

def extract_version_from_filename(url: str, patterns: List[str]) -> Optional[str]:
    filename = url.split('/')[-1]
    for pattern in patterns:
        match = re.search(pattern, filename)
        if match:
            return match.group(1)
    return None

def extract_version_from_text(text: str, pattern: str) -> Optional[str]:
    match = re.search(pattern, text)
    return match.group(1) if match else None

def extract_version_from_header(url: str, pattern: str) -> Optional[str]:
    try:
        resp = requests.head(url, timeout=10, allow_redirects=True)
        content_disp = resp.headers.get('Content-Disposition', '')
        match = re.search(pattern, content_disp, re.I)
        return match.group(1) if match else None
    except Exception:
        return None

def generate_wps_download_url(base_url: str) -> Optional[str]:
    """Generate WPS download URL with required signature.

    WPS CDN requires a time-based signature:
    - timestamp10: current Unix timestamp (10 digits)
    - k: MD5 hash of (secret_key + uri + timestamp10)
    """
    try:
        WPS_SECRET_KEY = "7f8faaaa468174dc1c9cd62e5f218a5b"

        # Parse URL to get URI (path part)
        parsed = re.match(r'https?://[^/]+(/.*)', base_url)
        if not parsed:
            return None
        uri = parsed.group(1)

        # Generate 10-digit timestamp
        timestamp10 = int(time.time())

        # Generate MD5 hash
        hash_input = f"{WPS_SECRET_KEY}{uri}{timestamp10}"
        md5hash = hashlib.md5(hash_input.encode()).hexdigest()

        # Construct signed URL
        signed_url = f"{base_url}?t={timestamp10}&k={md5hash}"
        return signed_url
    except Exception as e:
        print(f"Failed to generate WPS signed URL: {e}")
        return None

def fetch_apt_repo_version(apt_repo_url: str, package_name: str) -> Tuple[Optional[str], Optional[str]]:
    """Fetch version and download URL from APT repository Packages.gz."""
    try:
        # Download and decompress Packages.gz
        resp = requests.get(apt_repo_url, timeout=15)
        resp.raise_for_status()
        
        # Decompress gzip
        import gzip
        from io import BytesIO
        packages_data = gzip.decompress(resp.content).decode('utf-8')
        
        # Parse Packages file to find the package
        # Format: Package: name\nVersion: version\n...\n\n
        current_pkg = None
        current_ver = None
        current_file = None
        
        for line in packages_data.split('\n'):
            line = line.strip()
            if line.startswith('Package: '):
                current_pkg = line[9:]
            elif line.startswith('Version: '):
                current_ver = line[9:]
            elif line.startswith('Filename: '):
                current_file = line[10:]
            elif line == '' and current_pkg:
                # End of package record
                if current_pkg == package_name:
                    # Found the package
                    # Build download URL
                    # apt_repo_url is like: https://.../dists/stable/main/binary-amd64/Packages.gz
                    base_url = apt_repo_url.rsplit('/dists/', 1)[0]
                    download_url = f"{base_url}/{current_file}"
                    return current_ver, download_url
                # Reset for next package
                current_pkg = None
                current_ver = None
                current_file = None
        
        # Check last package if file doesn't end with blank line
        if current_pkg == package_name and current_ver and current_file:
            base_url = apt_repo_url.rsplit('/dists/', 1)[0]
            download_url = f"{base_url}/{current_file}"
            return current_ver, download_url
            
        print(f"{package_name}: not found in APT repository")
        return None, None
        
    except Exception as e:
        print(f"Failed to fetch {package_name} from APT repository: {e}")
        return None, None

def fetch_github_release(repo: str, asset_pattern: str, version_pattern: Optional[str] = None) -> Tuple[Optional[str], Optional[str]]:
    """Fetch release info from GitHub using gh CLI (avoids API rate limits)."""
    import subprocess
    
    try:
        # Use gh CLI to get release info (no rate limit when authenticated)
        result = subprocess.run(
            ['gh', 'release', 'view', '--repo', repo, '--json', 'assets,tagName'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode != 0:
            # Fallback to API if gh CLI fails
            print(f"{repo}: gh CLI failed, falling back to API")
            return fetch_github_release_api(repo, asset_pattern, version_pattern)
        
        data = json.loads(result.stdout)
        tag = data.get('tagName', '')
        assets = data.get('assets', [])
        
        if not assets:
            print(f"{repo}: no assets found")
            return None, None

        matched_asset = None
        asset_match = None
        for asset in assets:
            asset_match = re.search(asset_pattern, asset['name'])
            if asset_match:
                matched_asset = asset
                break
        if not matched_asset:
            print(f"{repo}: no files matching asset pattern '{asset_pattern}'")
            return None, None

        download_url = matched_asset['url']
        
        # Try to extract version from asset_pattern capture group first
        if asset_match and asset_match.groups():
            version = asset_match.group(1)
        elif version_pattern:
            version_match = re.search(version_pattern, tag)
            if version_match:
                version = version_match.group(1)
            else:
                version_match = re.search(version_pattern, matched_asset['name'])
                version = version_match.group(1) if version_match else None
        else:
            version = tag.lstrip('v')
        if not version:
            version = "unknown"
            print(f"{repo}: cannot extract version, using 'unknown'")
        return version, download_url

    except Exception as e:
        print(f"{repo}: gh CLI error: {e}, falling back to API")
        return fetch_github_release_api(repo, asset_pattern, version_pattern)

def fetch_github_release_api(repo: str, asset_pattern: str, version_pattern: Optional[str] = None) -> Tuple[Optional[str], Optional[str]]:
    """Fallback: Fetch release info from GitHub API (may hit rate limits)."""
    api_url = f"https://api.github.com/repos/{repo}/releases/latest"
    headers = {}
    
    # Use GitHub token if available (increases rate limit from 60 to 5000/hour)
    token = os.environ.get('GITHUB_TOKEN')
    if token:
        headers['Authorization'] = f'token {token}'
    
    try:
        resp = requests.get(api_url, timeout=10, headers=headers)
        resp.raise_for_status()
        data = resp.json()
        tag = data.get('tag_name', '')
        assets = data.get('assets', [])
        if not assets:
            print(f"{repo}: no assets found")
            return None, None

        matched_asset = None
        asset_match = None
        for asset in assets:
            asset_match = re.search(asset_pattern, asset['name'])
            if asset_match:
                matched_asset = asset
                break
        if not matched_asset:
            print(f"{repo}: no files matching asset pattern '{asset_pattern}'")
            return None, None

        download_url = matched_asset['browser_download_url']
        
        # Try to extract version from asset_pattern capture group first
        if asset_match and asset_match.groups():
            version = asset_match.group(1)
        elif version_pattern:
            version_match = re.search(version_pattern, tag)
            if version_match:
                version = version_match.group(1)
            else:
                version_match = re.search(version_pattern, matched_asset['name'])
                version = version_match.group(1) if version_match else None
        else:
            version = tag.lstrip('v')
        if not version:
            version = "unknown"
            print(f"{repo}: cannot extract version，using 'unknown'")
        return version, download_url

    except Exception as e:
        print(f"Failed to fetch {repo} from GitHub Releases: {e}")
        return None, None

def fetch_github_release_multi(repo: str, asset_pattern: str, distro_pattern: str,
                                distro_mapping: Dict[str, str],
                                version_pattern: Optional[str] = None) -> Dict[str, Dict[str, str]]:
    """Fetch multi-distro release info from GitHub using gh CLI (avoids API rate limits)."""
    import subprocess
    
    try:
        # Use gh CLI to get release info (no rate limit when authenticated)
        result = subprocess.run(
            ['gh', 'release', 'view', '--repo', repo, '--json', 'assets,tagName'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode != 0:
            print(f"{repo}: gh CLI failed for multi-distro, falling back to API")
            return fetch_github_release_multi_api(repo, asset_pattern, distro_pattern,
                                                  distro_mapping, version_pattern)
        
        data = json.loads(result.stdout)
        tag = data.get('tagName', '')
        assets = data.get('assets', [])
        
        if not assets:
            print(f"{repo}: no assets found")
            return {}

        version = None
        if version_pattern:
            match = re.search(version_pattern, tag)
            if match:
                version = match.group(1)
        if not version:
            version = tag.lstrip('v')
        if not version:
            version = "unknown"
            print(f"{repo}: cannot extract version, using 'unknown'")

        result = {}
        for asset in assets:
            name = asset['name']
            asset_match = re.search(asset_pattern, name)
            if not asset_match:
                continue
            
            # Try to extract version from asset_pattern capture group
            if asset_match.groups():
                asset_version = asset_match.group(1)
            else:
                asset_version = version
            
            distro_match = re.search(distro_pattern, name)
            if not distro_match:
                continue
            distro_code = distro_match.group(1)
            distro_key = distro_mapping.get(distro_code)
            if not distro_key:
                print(f"{repo}: unmapped distro code '{distro_code}', skipping")
                continue
            download_url = asset['url']
            result[distro_key] = {
                "version": asset_version,
                "url": download_url
            }
        return result

    except Exception as e:
        print(f"{repo}: gh CLI error for multi-distro: {e}, falling back to API")
        return fetch_github_release_multi_api(repo, asset_pattern, distro_pattern,
                                              distro_mapping, version_pattern)

def fetch_github_release_multi_api(repo: str, asset_pattern: str, distro_pattern: str,
                                    distro_mapping: Dict[str, str],
                                    version_pattern: Optional[str] = None) -> Dict[str, Dict[str, str]]:
    """Fallback: Fetch multi-distro release info from GitHub API (may hit rate limits)."""
    api_url = f"https://api.github.com/repos/{repo}/releases/latest"
    headers = {}
    
    # Use GitHub token if available
    token = os.environ.get('GITHUB_TOKEN')
    if token:
        headers['Authorization'] = f'token {token}'
    
    try:
        resp = requests.get(api_url, timeout=10, headers=headers)
        resp.raise_for_status()
        data = resp.json()
        tag = data.get('tag_name', '')
        assets = data.get('assets', [])
        if not assets:
            print(f"{repo}: no assets found")
            return {}

        version = None
        if version_pattern:
            match = re.search(version_pattern, tag)
            if match:
                version = match.group(1)
        if not version:
            version = tag.lstrip('v')
        if not version:
            version = "unknown"
            print(f"{repo}: cannot extract version，using 'unknown'")

        result = {}
        for asset in assets:
            name = asset['name']
            asset_match = re.search(asset_pattern, name)
            if not asset_match:
                continue
            
            # Try to extract version from asset_pattern capture group
            if asset_match.groups():
                asset_version = asset_match.group(1)
            else:
                asset_version = version
            
            distro_match = re.search(distro_pattern, name)
            if not distro_match:
                continue
            distro_code = distro_match.group(1)
            distro_key = distro_mapping.get(distro_code)
            if not distro_key:
                print(f"{repo}: unmapped distro code '{distro_code}'，skipping")
                continue
            download_url = asset['browser_download_url']
            result[distro_key] = {
                "version": asset_version,
                "url": download_url
            }
        return result

    except Exception as e:
        print(f"Failed to fetch {repo} multi-release from GitHub Releases: {e}")
        return {}

def fetch_app(config: Dict) -> Tuple[str, Any]:
    name = config.get("name", "unknown")
    pkg_format = config.get("format", "deb")  # package format: deb or appimage
    extract_method = config.get("version_extract")
    package_keyword = config.get("package_keyword", name)

    # GitHub Releases multi-distro
    if extract_method == "github_release" and config.get("multi_distro"):
        repo = config.get("github_repo")
        asset_pattern = config.get("asset_pattern")
        distro_pattern = config.get("distro_pattern")
        distro_mapping = config.get("distro_mapping", {})
        version_pattern = config.get("version_pattern")
        if not repo or not asset_pattern or not distro_pattern:
            print(f"{name}: multi-distro config missing required fields")
            return name, {"version": "unknown", "url": "", "package_keyword": package_keyword}
        versions = fetch_github_release_multi(repo, asset_pattern, distro_pattern,
                                              distro_mapping, version_pattern)
        if not versions:
            return name, {"format": pkg_format, "version": "unknown", "url": "", "package_keyword": package_keyword}
        return name, {
            "format": pkg_format,
            "multi": True,
            "versions": versions,
            "package_keyword": package_keyword
        }

    # GitHub Releases single package
    if extract_method == "github_release":
        repo = config.get("github_repo")
        asset_pattern = config.get("asset_pattern")
        version_pattern = config.get("version_pattern")
        if not repo or not asset_pattern:
            print(f"{name}: GitHub release config missing repo or asset_pattern")
            return name, {"format": pkg_format, "version": "unknown", "url": "", "package_keyword": package_keyword}
        version, url = fetch_github_release(repo, asset_pattern, version_pattern)
        if version is None or url is None:
            return name, {"format": pkg_format, "version": "unknown", "url": "", "package_keyword": package_keyword}
        return name, {"format": pkg_format, "version": version, "url": url, "package_keyword": package_keyword}

    # APT Repository
    if extract_method == "apt_repo":
        apt_repo = config.get("apt_repo")
        apt_package = config.get("apt_package")
        if not apt_repo or not apt_package:
            print(f"{name}: APT repo config missing apt_repo or apt_package")
            return name, {"format": pkg_format, "version": "unknown", "url": "", "package_keyword": package_keyword}
        version, url = fetch_apt_repo_version(apt_repo, apt_package)
        if version is None or url is None:
            return name, {"format": pkg_format, "version": "unknown", "url": "", "package_keyword": package_keyword}
        return name, {"format": pkg_format, "version": version, "url": url, "package_keyword": package_keyword}

    # original web scraping logic
    page_url = config.get("page_url")
    fallback_url = config.get("fallback_url")
    patterns = config.get("download_url_patterns", [])

    download_url = None
    html = None
    if page_url:
        html = fetch_url_content(page_url)
        if html is not None:
            download_url = extract_download_url(html, patterns)
    if not download_url and fallback_url:
        download_url = fallback_url

    if not download_url:
        print(f"{name}: download link not found")
        return name, {"format": pkg_format, "version": "unknown", "url": "", "package_keyword": package_keyword}

    final_url = resolve_final_url(download_url)
    if not final_url:
        final_url = download_url

    version = None
    if extract_method == "filename":
        ver_pattern = config.get("version_pattern")
        # Special case: "current" means the URL always points to latest version
        if ver_pattern == "current":
            version = "latest"
        else:
            patterns: List[str] = [ver_pattern] if ver_pattern else []
            if "version_pattern_fallback" in config:
                fallback = config["version_pattern_fallback"]
                if fallback:
                    patterns.append(fallback)
            version = extract_version_from_filename(final_url, patterns)

    elif extract_method == "page" and html:
        version = extract_version_from_text(html, config.get("version_pattern", ""))
        if not version and "version_extract_fallback" in config:
            fallback_method = config["version_extract_fallback"]
            if fallback_method == "header":
                header_pattern = config.get("version_header_pattern", "")
                if header_pattern:
                    version = extract_version_from_header(download_url, header_pattern)

    if not version:
        version = "unknown"
        print(f"{name}: cannot extract version，using 'unknown'")

    # Special handling for WPS: generate signed URL
    if name == "wps":
        signed_url = generate_wps_download_url(final_url)
        if signed_url:
            final_url = signed_url

    return name, {"format": pkg_format, "version": version, "url": final_url, "package_keyword": package_keyword}

def main(config_file: str = "apps.json", output_dir: str = "."):
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            apps_config = json.load(f)
    except Exception as e:
        print(f"reading config file {config_file} failed: {e}")
        sys.exit(1)

    if not isinstance(apps_config, list):
        print(f"Configuration file {config_file} should be JSON array")
        sys.exit(1)

    results = {}
    for config in apps_config:
        name, data = fetch_app(config)
        results[name] = data

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "versions.json")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"generated {output_file}")

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Fetch application versions')
    parser.add_argument('config_file', nargs='?', default='apps.json', help='Path to apps.json config file')
    parser.add_argument('--output-dir', '-o', default='.', help='Output directory for versions.json')
    args = parser.parse_args()
    main(args.config_file, args.output_dir)