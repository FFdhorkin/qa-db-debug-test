# Use a Node.js image
FROM node:14

# Set environment variables
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    POSTGRES_USER=testuser \
    POSTGRES_PASSWORD=password \
    POSTGRES_DB=testdb

# Install PostgreSQL and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql postgresql-contrib && \
    rm -rf /var/lib/apt/lists/*

# Configure PostgreSQL authentication
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/11/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/11/main/postgresql.conf

# Set up the working directory for the app
WORKDIR /app

# Copy just the starter database (we'll copy the rest later). This avoids needing a rebuild of the postgres db if tests change
COPY setup_db.sql.b64 .

# Start PostgreSQL, create the database, user, and decode and execute the Base64 SQL commands
RUN service postgresql start && \
    su - postgres -c "psql -c 'CREATE DATABASE $POSTGRES_DB;'" && \
    su - postgres -c "psql -c \"CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';\"" && \
    su - postgres -c "psql -c 'GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;'" && \
    base64 -d setup_db.sql.b64 | \
    su - postgres -c "psql -d $POSTGRES_DB -f -" && \
    service postgresql stop

# Copy remaining files into container
COPY . .

# Install Node.js dependencies
RUN npm install

EXPOSE 5432

# Run the test when the container starts
CMD ["sh", "./run_test.sh"]
