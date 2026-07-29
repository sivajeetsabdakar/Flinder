from pathlib import Path
import os

import psycopg
from dotenv import load_dotenv


def main() -> None:
    backend_dir = Path(__file__).resolve().parents[1]
    repo_dir = backend_dir.parent
    load_dotenv(backend_dir / ".env")

    database_url = os.environ["DATABASE_URL"]
    migration_dir = repo_dir / "database" / "migrations"
    migrations = sorted(migration_dir.glob("*.sql"))

    with psycopg.connect(database_url, autocommit=True) as conn:
        with conn.cursor() as cursor:
            for migration in migrations:
                cursor.execute(migration.read_text(encoding="utf-8"))
                print(f"applied {migration.name}")


if __name__ == "__main__":
    main()
