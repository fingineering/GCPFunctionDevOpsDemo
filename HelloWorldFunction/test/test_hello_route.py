from platform import python_branch
from functions_framework import create_app
import pathlib
from dotenv import load_dotenv

load_dotenv()

FUNCTIONS_DIR = pathlib.Path(__file__).resolve().parent.parent


def test_hello_route():
    source = FUNCTIONS_DIR / "main.py"
    target = "hello_world"
    client = create_app(target, source).test_client()

    resp = client.get("/")
    assert resp.status_code == 200
    # should test for more than the basic response status code
    return