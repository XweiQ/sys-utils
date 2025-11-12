#!/usr/bin/env python3
"""
download_hf.py

Download a model and/or dataset from Hugging Face Hub directly into /home/models/.

Usage examples:
  python download_hf.py --model gpt2
  python download_hf.py --dataset imdb
  python download_hf.py --model bert-base-uncased --dataset glue --revision main

Dependencies:
  pip install huggingface_hub datasets

The script will place files directly under:
  /home/models/<repo_id_with_underscores>/...
  /home/models/datasets/<dataset_id_with_underscores>/...

It supports private repos/datasets via --token or the HUGGINGFACE_TOKEN env var.
"""

import argparse
import os
import sys
from typing import Optional


def download_model(repo_id: str, dest_root: str = "/home/models", revision: Optional[str] = None, token: Optional[str] = None):
    """Download a model repository snapshot directly to dest_root/<model_name>.

    Uses huggingface_hub.snapshot_download with local_dir to place files directly in target directory.
    """
    from huggingface_hub import snapshot_download

    # Use only the model name part after the slash, or the full name if no slash
    model_name = repo_id.split("/")[-1]
    dest_dir = os.path.join(dest_root, model_name)
    os.makedirs(dest_dir, exist_ok=True)
    # local_dir rather than cache_dir
    kwargs = {"local_dir": dest_dir, "local_dir_use_symlinks": False}
    if token:
        kwargs["token"] = token
    if revision:
        kwargs["revision"] = revision

    print(f"Downloading model '{repo_id}' -> {dest_dir} ...")
    path = snapshot_download(repo_id, **kwargs)
    return path


def download_dataset(dataset_id: str, dest_root: str = "/home/models", split: Optional[str] = None, token: Optional[str] = None):
    """Load a dataset with `datasets` and save it to disk under dest_root/datasets/<dataset_id>/.

    If the dataset returns a DatasetDict, each split is saved to a separate subdirectory.
    """
    from datasets import load_dataset

    dest_dir = os.path.join(dest_root, "datasets", dataset_id.replace("/", "_"))
    os.makedirs(dest_dir, exist_ok=True)

    load_kwargs = {}
    if token:
        load_kwargs["token"] = token

    print(f"Loading dataset '{dataset_id}' (split={split}) ...")
    # load_dataset may return a Dataset or a DatasetDict
    ds = load_dataset(dataset_id, split=split, **load_kwargs) if split else load_dataset(dataset_id, **load_kwargs)

    if isinstance(ds, dict):
        for k, v in ds.items():
            out = os.path.join(dest_dir, k)
            print(f"Saving split '{k}' to {out} ...")
            v.save_to_disk(out)
        print(f"Saved dataset to {dest_dir} (splits: {', '.join(ds.keys())})")
    else:
        out = os.path.join(dest_dir, split if split else "default")
        print(f"Saving dataset to {out} ...")
        ds.save_to_disk(out)
        print(f"Saved dataset to {out}")

    return dest_dir


def parse_args():
    p = argparse.ArgumentParser(description="Download model and/or dataset from Hugging Face to /home/models/")
    p.add_argument("--model", type=str, help="Model repo id on HF, e.g. 'gpt2' or 'owner/repo'")
    p.add_argument("--dataset", type=str, help="Dataset id on HF, e.g. 'imdb' or 'glue' or 'owner/dataset'")
    p.add_argument("--revision", type=str, default=None, help="Revision/branch/commit for model download")
    p.add_argument("--split", type=str, default=None, help="Optional dataset split to download (e.g. 'train')")
    p.add_argument("--token", type=str, default=os.environ.get("HUGGINGFACE_TOKEN"), help="Hugging Face token or set HUGGINGFACE_TOKEN env var")
    p.add_argument("--dest", type=str, default="/home/models", help="Destination root (default: /home/models)")
    return p.parse_args()


def main():
    args = parse_args()

    if not args.model and not args.dataset:
        print("Please specify at least --model or --dataset. Use -h for help.")
        sys.exit(1)

    if args.model:
        try:
            download_model(args.model, dest_root=args.dest, revision=args.revision, token=args.token)
        except Exception as e:
            print(f"Error downloading model {args.model}: {e}")
            sys.exit(2)

    if args.dataset:
        try:
            download_dataset(args.dataset, dest_root=args.dest, split=args.split, token=args.token)
        except Exception as e:
            print(f"Error downloading dataset {args.dataset}: {e}")
            sys.exit(3)

    print("Done.")


if __name__ == "__main__":
    main()
