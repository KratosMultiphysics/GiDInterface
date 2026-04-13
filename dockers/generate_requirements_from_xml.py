import argparse
import xml.etree.ElementTree as ET
from pathlib import Path


def build_requirements(xml_path: Path) -> list[str]:
    root = ET.parse(xml_path).getroot()
    requirements: list[str] = []
    seen: set[str] = set()

    for package in root.findall("./Program/PythonPackages/Package"):
        name = (package.get("Name") or "").strip()
        version = (package.get("Version") or "").strip()
        if not name:
            continue

        requirement = f"{name}=={version}" if version else name
        if requirement in seen:
            continue

        requirements.append(requirement)
        seen.add(requirement)

    return requirements


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xml", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    xml_path = Path(args.xml)
    out_path = Path(args.out)
    requirements = build_requirements(xml_path)
    requirements.append("numpy")

    out_path.write_text("\n".join(requirements) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
