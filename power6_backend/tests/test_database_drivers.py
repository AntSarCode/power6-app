"""Exercise deployment driver loading without connecting to a database."""
import pytest
from sqlalchemy import create_engine


@pytest.mark.parametrize("scheme", [
    "postgresql", "postgresql+psycopg", "postgresql+psycopg2",
])
def test_postgres_driver_loads_from_deployment_requirements(scheme):
    # create_engine imports the DBAPI immediately. This is the exact startup
    # step that failed on Render; SQLite-only tests never exercised it.
    engine = create_engine(f"{scheme}://test:test@127.0.0.1:1/test")
    try:
        assert engine.dialect.dbapi.__name__ in {"psycopg", "psycopg2"}
        if "+" in scheme:
            assert engine.dialect.driver == scheme.split("+", 1)[1]
    finally:
        engine.dispose()
