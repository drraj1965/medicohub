from __future__ import annotations

import os
import sys
import traceback
from pathlib import Path

import uvicorn


def _log_path() -> Path:
    if getattr(sys, "frozen", False):
        base = Path(sys.executable).resolve().parent / "backend_data"
    else:
        base = Path(__file__).resolve().parent / "data"
    base.mkdir(parents=True, exist_ok=True)
    return base / "packaged_backend.log"


def _append_log(message: str) -> None:
    _log_path().open("a", encoding="utf-8").write(message + "\n")


def main() -> None:
    port = int(os.getenv("MEDICOHUB_BACKEND_PORT", "8012"))
    _append_log(f"Starting packaged backend on port {port}")
    try:
        from backend_fastapi.main import app

        _append_log("Imported backend_fastapi.main.app successfully")
        uvicorn.run(
            app,
            host="127.0.0.1",
            port=port,
            reload=False,
            log_level="warning",
            log_config=None,
            access_log=False,
        )
    except Exception:
        _append_log("Startup failure:")
        _append_log(traceback.format_exc())
        raise


if __name__ == "__main__":
    main()
