<br />
<div align="center">

  <h1 align="center">Linux Cluster Monitoring Agent</h1>

  <p align="center">
    <br />
    <a href="https://github.com/ianstewart4/grocery-price-tracker/issues">Report Bug</a>
    ·
    <a href="https://github.com/ianstewart4/grocery-price-tracker/issues">Request Feature</a>
  </p>
</div>

# Introduction

This project can be used to set up a monitoring agent for a linux VM. It will allow users to quickly set up a PostgreSQL instance on an Alpine container using Docker, then using a bash terminal users can run simple commands to create the necessary database and tables to store virtual machine hardware stats in a host_info table and usage stats in a host_usage table by setting up a crontab job that will collect and then insert usage stats every minute. Users can then query the respective databases to get a quick high level view of their cluster's capacity and performance in real time.

# Quick Start
```
# Create DB Container
./scripts/psql_docker.sh create db_username db_password

# Start DB Container
./scripts/psql_docker.sh start db_username db_password

# Create tables
psql -h localhost -U postgres -d host_agent -f ddl.sql

# Run host_info.sh
bash scripts/host_info.sh psql_host psql_port db_name psql_user psql_password

# Run host_usage.sh
bash scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password

# Open a crontab file and edit
bash crontab -e
# Paste the following using your path
* * * * * bash /YOUR/PATH/TO/scripts/host_usage.sh localhost 5432 host_agent postgres password > /tmp/host_usage.log
```
# Implementation

## Architecture

![Architecture](https://github.com/jarviscanada/jarvis_data_eng_IanStewart/assets/44770822/df0dc585-bcb9-46f8-9c54-7ade59de402a)

Each Linux virtual machine will be connected through a network switch. Each one will then run the `psql_docker.sh` script to set up and start the docker container and then run the `ddl.sql` to create the necessary tables. Then each will run `host_info.sh` once and insert the output to a database on the primary node. Then `host_usage.sh` once every minute and insert data to the primary node where it can be queried from. 

## Database Modeling
### `host_info`

| Column     | Description                                                           |
|------------|-----------------------------------------------------------------------|
| id         | Primary key for the table. Starts at 1 and automatically increments |
| hostname   | Full name of the host                                                 |
| cpu_number | Number of CPUs on the host                                            |
| cpu_model  | Model of the CPU                                                      |
| cpu_mhz    | Clock speed of the CPU in megahertz                                   |
| l2_cache   | Level 2 cache size                                                    |
| timestamp  | Time when the record was created                                      |
| total_mem  | Total memory of the host                                              |
### `host_usage`

| Column         | Description                                             |
| -------------- | ------------------------------------------------------- |
| timestamp      | Time the record was created                             |
| host_id        | The id of the virtual machine the record was taken from |
| memory_free    | Free memory on the host                                 |
| cpu_idle       | CPU idle percentage                                     |
| cpu_kernel     | CPU kernel usage percentage                             |
| disk_io        | Disk input/output usage                                 |
| disk_available | Available disk space  

## Script description
`psql_docker.sh` creates or starts/stops a PostgreSQL instance with Alpine Linux on a Docker container. 

`ddl.sql`  creates the required host_agent database and respective tables to hold the stats and usage data 

`host_info.sh` collects and parses the virtual machine hardware stats then inserts them into the host_info table

`host_usage.sh` collects and parses the virtual machine's hardware usage stats and then inserts it into the host_usage table.
## Usage

### 1. Database Setup
From the bash terminal, navigate to the linux_sql directory if not already there, then run the following commands to create and then start the Linux Alpine Docker container
```
# Create
./scripts/psql_docker.sh create db_username db_password

# Start
./scripts/psql_docker.sh start db_username db_password
```
Create tables using `ddl.sql`
```
# Create tables
psql -h localhost -U postgres -d host_agent -f ddl.sql
```
### 2. Run host_info.sh
Insert hardware specs data into the database by running `host_info.sh`
```
# Run host_info.sh
bash scripts/host_info.sh psql_host psql_port db_name psql_user psql_password
```
### 3. Run host_usage.sh
Insert hardware usage data into the database by running `host_usage.sh`
```
# Run host_usage.sh
bash scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password
```
### 4. Start crontab job
Start a crontab job to run `host_usage.sh` every minute
```
# Open a crontab file and edit
crontab -e
# Paste the following using your path
* * * * * bash /YOUR/PATH/TO/scripts/host_usage.sh localhost 5432 host_agent postgres password > /tmp/host_usage.log
```

# Test
To ensure the DDL script executed correctly I ran the \d command in psql to confirm the tables were created and then inserted data to the tables and ran a SELECT * on each to confirm the data inserted successfully.

# Deployment
Each feature was built and then individually tested then pushed to Github. Once the core components were complete they were tested together by running them in order to simulate real-world usage (psql_docker.sh -> ddl.sql -> host_info.sh -> host_usage.sh). Then a crontab schedule was implemented to run the host_usage script every minute. Finally the SQL tables were reviewed to ensure functionality.

# Enhancements
- [ ] Automate full setup process so that users can set up the monitoring agent by running a single bash script.
- [ ] Alerts to catch issues based on user-specified thresholds (eg. disk usage, CPU usage, memory usage) so users can avoid possible downtime from insufficient resources (ex. running out of memory or disk space).
- [ ] Live data visualization so users can choose a window (10 minutes, 1 hour, 1 day, etc.) and pull up a chart that shows whichever stats they choose over that time.
