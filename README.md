# Development Docker Compose Setup

## Table of Contents
- [Introduction](#introduction)
- [Directory Structure](#directory-structure)
- [Docker Compose Setup](#docker-compose-setup)
  - [Locale Settings](#locale-settings)
  - [Docker Compose File](#docker-compose-file)
  - [Initial Database Setup with init.sql](#initial-database-setup-with-initsql)
  - [Data Persistence with pg_data](#data-persistence-with-pg_data)
- [Usage](#usage)
  - [Start the Services](#start-the-services)
  - [Access pgAdmin](#access-pgadmin)
  - [Connect to the Database](#connect-to-the-database)
- [Troubleshooting](#troubleshooting)
- [License](#license)

# Introduction
This repository contains a Docker Compose configuration to set up a development environment with PostgreSQL and pgAdmin. It uses `docker-compose` for service management, `secrets` for storing sensitive data, and `.env` for configuring environment variables.

## Directory Structure
```
development-docker-compose/
│
├── docker-compose.yml          # Docker Compose file
├── Dockerfile                  # Dockerfile for the PostgreSQL container
├── secrets/
│   ├── postgres_user.txt       # Contains the PostgreSQL username
│   └── postgres_password.txt   # Contains the PostgreSQL password
└── .env                        # Contains environment variables for pgAdmin
```

## Preparation

1. **Configure PostgreSQL Credentials:**
   
   Create two files in the `secrets/` directory:
   
   - **`postgres_user.txt`**: Contains the PostgreSQL username.
   - **`postgres_password.txt`**: Contains the PostgreSQL password.
   
   The content of these files should be the username and password in plain text.

   Example:
   ```
   secrets/postgres_user.txt: someusername
   secrets/postgres_password.txt: password
   ```


2. **Configure pgAdmin Credentials:**

Create a `.env` file in the root directory containing the pgAdmin credentials:

`.env`:
```env
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=my_pgadmin_password
```

## Docker Compose Setup

This `docker-compose.yml` file currently starts **two core services** essential for the development environment:

- **PostgreSQL**: A PostgreSQL database with the following settings:
  - **Database name**: `Bibliotheksverwaltung`
  - **Locale settings**: Configured specifically for German locale `de_DE.UTF-8`, ensuring proper handling of German-specific data formats and collations.
  - **Credentials**: Managed securely through Docker secrets.

- **pgAdmin**: A web-based PostgreSQL management interface.
  - **Credentials**: Configured via environment variables stored in a `.env` file.

### Locale Settings

In the PostgreSQL service, the following locale settings have been configured to ensure that the database handles German-specific formats correctly:

- **`lc_collate=de_DE.UTF-8`**: Defines the collation order (sorting rules) for strings.
- **`lc_ctype=de_DE.UTF-8`**: Specifies the character classification (e.g., upper, lower, digit).
- **`lc_monetary=de_DE.UTF-8`**: Sets the default format for currency.
- **`lc_numeric=de_DE.UTF-8`**: Determines the format for numbers (e.g., decimal points).
- **`lc_time=de_DE.UTF-8`**: Sets the format for time and date.
- **`lc_messages=en_US.UTF-8`**: While German locales are set, system messages are configured in English for broader accessibility.

These settings are chosen based on my personal preference and familiarity with the German locale. However, you can configure the locale settings according to your own needs. For more information on how to configure these settings, refer to the [PostgreSQL Locales documentation](https://www.postgresql.org/docs/current/locale.html).


### Docker Compose File

```yaml
version: '3.8'

services:

  postgres:
    build: .
    environment:
      POSTGRES_DB: Bibliotheksverwaltung
      POSTGRES_INITDB_ARGS: "--locale=de_DE.UTF-8 --lc-collate=de_DE.UTF-8 --lc-ctype=de_DE.UTF-8 --lc-messages=en_US.UTF-8 --lc-monetary=de_DE.UTF-8 --lc-numeric=de_DE.UTF-8 --lc-time=de_DE.UTF-8"
      PGDATA: /var/lib/postgresql/data/pgdata
      POSTGRES_USER_FILE: /run/secrets/postgres-admin-username
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres-admin-password
    ports:
      - 5432:5432
    secrets:
      - postgres-admin-username
      - postgres-admin-password
    restart: unless-stopped
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ../datalayer/init.sql:/docker-entrypoint-initdb.d/init.sql

  pgadmin:
    image: dpage/pgadmin4:8.7
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
    ports:
      - 5050:80
    restart: unless-stopped
    volumes:
     - pgadmin_data:/var/lib/pgadmin
    depends_on:
      - postgres

secrets:
  postgres-admin-username:
    file: ./secrets/postgres_user.txt
  postgres-admin-password:
    file: ./secrets/postgres_password.txt

volumes:
  pg_data:
  pgadmin_data:
```

### Dockerfile

The current setup utilizes a custom `Dockerfile` to enhance the PostgreSQL container with additional locale support. This is an essential part of the foundation, ensuring that the database is properly configured for the environment. As the project evolves, this Dockerfile may be expanded to include additional configurations or optimizations to support future development needs. This setup is currently tailored to meet the immediate requirements of the project, but is flexible enough to accommodate further enhancements as the project continues to grow and develop.

```Dockerfile
FROM postgres:latest

# Install locale and locales package
RUN apt-get update && apt-get install -y locales

# Add the desired locales to /etc/locale.gen
RUN echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

# Generate the locales
RUN locale-gen
```

### Initial Database Setup with `init.sql`
The init.sql file plays a crucial role in the initial setup of the database. It contains the SQL commands needed to create the necessary tables, indexes, and initial configurations for the project. This script is automatically executed when the PostgreSQL container is first started, ensuring that the database is correctly initialized and ready for use right from the beginning.

You can find the init.sql in the datalayer directory, which is mounted into the PostgreSQL container via the docker-compose.yml file:

```yaml
volumes:
  - ../datalayer/init.sql:/docker-entrypoint-initdb.d/init.sql
```

### Data Persistence with `pg_data`
To ensure that your database data is not lost when the Docker containers are stopped or restarted, a named volume pg_data is used. This volume stores the PostgreSQL data files on your host machine, making the data persistent across container lifecycles.
Here is how it’s configured in the `docker-compose.yml`:
```yaml
volumes:
  pg_data:/var/lib/postgresql/data
```

## Usage

### Start the Services

To start the PostgreSQL and pgAdmin services, run following command in the terminal:

```zsh
docker-compose up
```

### Access pgAdmin
Open a browser and go to http://localhost:5050. Log in using the credentials specified in the `.env` file.

### Connect to the Database
In pgAdmin, you can now add a new server to connect to the PostgreSQL database:

- Host name/address: postgres
- Port: 5432
- Maintenance database: Bibliotheksverwaltung
- Username: The value from postgres_user.txt.
- Password: The value from postgres_password.txt.






