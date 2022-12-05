# Docker Debian to PHP8.1 MySQL 8.0 Nginx 1.22 
## Environment Variables

This project run for docker-compose.yml variable add need

`MYSQL_DATABASE`
`MYSQL_USER`
`MYSQL_ROOT_PASSWORD`
`MYSQL_PASSWORD`

## Run

project directory go

```bash
  cd wpdocker
```

Tool run

```bash
  docker build -t nginx-php-mysql .
```

```bash
  docker compose up -d
```
