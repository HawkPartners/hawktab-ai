#!/usr/bin/env python3
"""
Convert Excel workbooks to CSV files.

For each .xlsx file, exports each sheet as a separate CSV:
  original_file_name__SheetName.csv

Usage:
  python scripts/xlsx-to-csv.py                    # Process all xlsx in data/test-data
  python scripts/xlsx-to-csv.py path/to/folder    # Process all xlsx in specified folder
  python scripts/xlsx-to-csv.py path/to/file.xlsx # Process single file
"""

import sys
import os
import glob
from pathlib import Path

try:
    import pandas as pd
except ImportError:
    print("pandas not found. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pandas", "openpyxl"])
    import pandas as pd


def convert_xlsx_to_csv(xlsx_path: str, output_dir: str = None) -> list[str]:
    """
    Convert an Excel file to CSV(s), one per sheet.

    Args:
        xlsx_path: Path to the .xlsx file
        output_dir: Directory for output CSVs (defaults to same directory as xlsx)

    Returns:
        List of created CSV file paths
    """
    xlsx_path = Path(xlsx_path)
    if output_dir is None:
        output_dir = xlsx_path.parent
    else:
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

    # Get base name without extension
    base_name = xlsx_path.stem

    # Read all sheets
    xlsx = pd.ExcelFile(xlsx_path)
    sheet_names = xlsx.sheet_names

    created_files = []

    for sheet_name in sheet_names:
        # Read the sheet
        df = pd.read_excel(xlsx, sheet_name=sheet_name)

        # Create output filename: basename__sheetname.csv
        # Sanitize sheet name for filename
        safe_sheet_name = sheet_name.replace("/", "-").replace("\\", "-").replace(" ", "_")
        csv_filename = f"{base_name}__{safe_sheet_name}.csv"
        csv_path = output_dir / csv_filename

        # Write CSV
        df.to_csv(csv_path, index=False)
        created_files.append(str(csv_path))
        print(f"  Created: {csv_path.name}")

    return created_files


def process_directory(directory: str) -> dict:
    """
    Process all xlsx files in a directory (recursively).

    Returns:
        Dict mapping xlsx files to their created CSVs
    """
    directory = Path(directory)
    xlsx_files = list(directory.glob("**/*.xlsx"))

    if not xlsx_files:
        print(f"No .xlsx files found in {directory}")
        return {}

    print(f"Found {len(xlsx_files)} Excel files\n")

    results = {}
    for xlsx_file in sorted(xlsx_files):
        print(f"Processing: {xlsx_file.relative_to(directory)}")
        try:
            created = convert_xlsx_to_csv(xlsx_file)
            results[str(xlsx_file)] = created
        except Exception as e:
            print(f"  ERROR: {e}")
            results[str(xlsx_file)] = []

    return results


def main():
    # Determine input path
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    else:
        # Default to data/test-data
        script_dir = Path(__file__).parent
        input_path = script_dir.parent / "data" / "test-data"

    input_path = Path(input_path)

    if not input_path.exists():
        print(f"Error: Path does not exist: {input_path}")
        sys.exit(1)

    if input_path.is_file():
        if input_path.suffix.lower() != ".xlsx":
            print(f"Error: Not an Excel file: {input_path}")
            sys.exit(1)
        print(f"Processing single file: {input_path}")
        convert_xlsx_to_csv(input_path)
    else:
        results = process_directory(input_path)

        # Summary
        total_csvs = sum(len(v) for v in results.values())
        successful = sum(1 for v in results.values() if v)
        print(f"\n{'='*50}")
        print(f"Summary: {successful}/{len(results)} files converted")
        print(f"Total CSVs created: {total_csvs}")


if __name__ == "__main__":
    main()
