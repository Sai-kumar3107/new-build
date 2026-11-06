"""Vercel entrypoint: runs the FastAPI app (backend/server.py) as a serverless Python Function.

`app` is defined at the top level of this file on purpose: Vercel's Python runtime detects the
function by looking for a top-level `app` (ASGI) object.

If a required environment variable is missing, or the real app fails to import, this serves a clear
JSON error instead of Vercel's generic 500 FUNCTION_INVOCATION_FAILED. Names only, never values.
"""
import os
import sys
import traceback
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import JSONResponse

_here = Path(__file__).resolve().parent
for _p in (_here.parent, _here.parent / "backend"):
    if (_p / "server.py").exists() and str(_p) not in sys.path:
        sys.path.insert(0, str(_p))

_REQUIRED = ("JWT_SECRET", "SUPABASE_DB_URL")


def _fallback(detail: str, extra: dict) -> FastAPI:
    fallback = FastAPI(title="RCortexa API (not ready)", docs_url=None, redoc_url=None, openapi_url=None)

    @fallback.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"])
    async def _not_ready(path: str):
        return JSONResponse({"detail": detail, **extra}, status_code=503)

    return fallback


def _build_app() -> FastAPI:
    missing = [name for name in _REQUIRED if not os.environ.get(name, "").strip()]
    if missing:
        print(f"[rcortexa] Missing required environment variable(s): {', '.join(missing)}", file=sys.stderr)
        return _fallback(
            "Server is not configured. Set the missing environment variable(s) in Vercel and redeploy.",
            {"missing": missing},
        )
    try:
        from server import app as real_app
        return real_app
    except Exception as exc:  # full traceback goes to the Vercel function logs only
        traceback.print_exc()
        return _fallback(
            "The API failed to start. See the Vercel function logs for the full error.",
            {"error": type(exc).__name__},
        )


app = _build_app()
