#!/usr/bin/env python3
import re
import json
import requests
import sys
from typing import Dict, List, Optional, Tuple, Any

def fetch_url_content(url: str) -> Optional[str]:
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        return resp.text
    except Exception as e:
        print(f"获取 {url} 失败: {e}")
        return None

def resolve_final_url(url: str) -> Optional[str]:
    try:
        resp = requests.head(url, timeout=10, allow_redirects=True)
        return resp.url
    except Exception as e:
        print(f"解析重定向 URL 失败: {e}")
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

def fetch_github_release(repo: str, asset_pattern: str, version_pattern: Optional[str] = None) -> Tuple[Optional[str], Optional[str]]:
    api_url = f"https://api.github.com/repos/{repo}/releases/latest"
    try:
        resp = requests.get(api_url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        tag = data.get('tag_name', '')
        assets = data.get('assets', [])
        if not assets:
            print(f"{repo}: 没有找到任何资产")
            return None, None

        matched_asset = None
        for asset in assets:
            if re.search(asset_pattern, asset['name']):
                matched_asset = asset
                break
        if not matched_asset:
            print(f"{repo}: 没有找到匹配资产模式 '{asset_pattern}' 的文件")
            return None, None

        download_url = matched_asset['browser_download_url']
        if version_pattern:
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
            print(f"{repo}: 无法提取版本号，使用 'unknown'")
        return version, download_url

    except Exception as e:
        print(f"从 GitHub Releases 获取 {repo} 失败: {e}")
        return None, None

def fetch_github_release_multi(repo: str, asset_pattern: str, distro_pattern: str,
                                distro_mapping: Dict[str, str],
                                version_pattern: Optional[str] = None) -> Dict[str, Dict[str, str]]:
    api_url = f"https://api.github.com/repos/{repo}/releases/latest"
    try:
        resp = requests.get(api_url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        tag = data.get('tag_name', '')
        assets = data.get('assets', [])
        if not assets:
            print(f"{repo}: 没有找到任何资产")
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
            print(f"{repo}: 无法提取版本号，使用 'unknown'")

        result = {}
        for asset in assets:
            name = asset['name']
            if not re.search(asset_pattern, name):
                continue
            match = re.search(distro_pattern, name)
            if not match:
                continue
            distro_code = match.group(1)
            distro_key = distro_mapping.get(distro_code)
            if not distro_key:
                print(f"{repo}: 未映射的发行版代号 '{distro_code}'，跳过")
                continue
            result[distro_key] = {
                "version": version,
                "url": asset['browser_download_url']
            }
        return result

    except Exception as e:
        print(f"从 GitHub Releases 获取 {repo} 多发行版失败: {e}")
        return {}

def fetch_app(config: Dict) -> Tuple[str, Any]:
    name = config.get("name", "unknown")
    extract_method = config.get("version_extract")
    package_keyword = config.get("package_keyword", name)

    # GitHub Releases 多发行版
    if extract_method == "github_release" and config.get("multi_distro"):
        repo = config.get("github_repo")
        asset_pattern = config.get("asset_pattern")
        distro_pattern = config.get("distro_pattern")
        distro_mapping = config.get("distro_mapping", {})
        version_pattern = config.get("version_pattern")
        if not repo or not asset_pattern or not distro_pattern:
            print(f"{name}: 多发行版配置缺少必要字段")
            return name, {"version": "unknown", "url": "", "package_keyword": package_keyword}
        versions = fetch_github_release_multi(repo, asset_pattern, distro_pattern,
                                              distro_mapping, version_pattern)
        if not versions:
            return name, {"version": "unknown", "url": "", "package_keyword": package_keyword}
        return name, {
            "multi": True,
            "versions": versions,
            "package_keyword": package_keyword
        }

    # GitHub Releases 单包
    if extract_method == "github_release":
        repo = config.get("github_repo")
        asset_pattern = config.get("asset_pattern")
        version_pattern = config.get("version_pattern")
        if not repo or not asset_pattern:
            print(f"{name}: GitHub release 配置缺少 repo 或 asset_pattern")
            return name, {"version": "unknown", "url": "", "package_keyword": package_keyword}
        version, url = fetch_github_release(repo, asset_pattern, version_pattern)
        if version is None or url is None:
            return name, {"version": "unknown", "url": "", "package_keyword": package_keyword}
        return name, {"version": version, "url": url, "package_keyword": package_keyword}

    # 原有的网页抓取逻辑
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
        print(f"{name}: 未找到下载链接")
        return name, {"version": "unknown", "url": "", "package_keyword": package_keyword}

    final_url = resolve_final_url(download_url)
    if not final_url:
        final_url = download_url

    version = None
    if extract_method == "filename":
        patterns = [config.get("version_pattern")]
        if "version_pattern_fallback" in config:
            patterns.append(config["version_pattern_fallback"])
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
        print(f"{name}: 无法提取版本号，使用 'unknown'")

    return name, {"version": version, "url": final_url, "package_keyword": package_keyword}

def main(config_file: str = "apps.json"):
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            apps_config = json.load(f)
    except Exception as e:
        print(f"读取配置文件 {config_file} 失败: {e}")
        sys.exit(1)

    if not isinstance(apps_config, list):
        print(f"配置文件 {config_file} 应为 JSON 数组")
        sys.exit(1)

    results = {}
    for config in apps_config:
        name, data = fetch_app(config)
        results[name] = data

    output_file = "versions.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"已生成 {output_file}")

if __name__ == '__main__':
    config_file = sys.argv[1] if len(sys.argv) > 1 else "apps.json"
    main(config_file)