# Z-Dax
NONE

start command
``rake render:config service:backend vault:setup render:config && docker-compose down && rake render:config service:all db:setup && docker-compose down && rake service:all vault:unseal``
