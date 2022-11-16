# Z-Dax

Z-Dax is an project template deployment ZSmartex Exchange in `docker-compose` write by [@huuhait](https://github.com/huuhait).

Demo exchange running: [ZSmartex Demo](https://demo.zsmartex.com/)

## Getting started with ZSmartex

### 1. Get the VM

Minimum VM requirements for Z-Dax:
 * 32GB of RAM
 * 16 core dedicated CPU
 * 300GB disk space

A VM from any cloud provider like DigitalOcean, Vultr, GCP, AWS as well as any dedicated server with Ubuntu, Debian or Centos would work

### 2. Prepare the VM

#### 2.1 Create Unix user
SSH using root user, then create new user for the application
```bash
useradd -g users -s `which bash` -m app
```

#### 2.2 Install Docker and docker compose

We highly recommend using docker and compose from docker.com install guide instead of the system provided package, which would most likely be deprecated.

Docker follow instruction here: [docker](https://docs.docker.com/install/)
Docker compose follow steps: [docker compose](https://docs.docker.com/compose/install/)

#### 2.3 Install ruby in user app

##### 2.3.1 Change user using
```bash
su - app
```

##### 2.3.2 Clone Z-Dax
```bash
git clone https://github.com/zsmartex/z-dax.git
```
##### 2.3.3 Install RVM
```bash
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
cd app
rvm install .
```

### 3. Bundle install dependencies

```bash
bundle install
rake -T # To see if ruby and lib works
```

Using `rake -T` you can see all available commands, and can create new ones in `lib/tasks`

### 4. Setup everything

#### 4.1 Configure your domain
If using a VM you can point your domain name to the VM ip address before this stage.
Recommended if you enabled SSL, for local development edit the `/etc/hosts`

Insert in file `/etc/hosts`
```
0.0.0.0 www.app.local
0.0.0.0 sync.app.local
0.0.0.0 adminer.app.local
```

#### 4.2 Setup Database and Vault

```bash
rake render:config service:proxy service:backend db:setup
```

#### 4.3 Setup Kafka Connect

Go to [Redpanda Console](http://data.app.local) and create connectors:

* Remember to change the `app.local` to your domain name

Barong database connector:
```json
{
    "column.exclude.list": "public.users.password_digest,public.users.data",
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.dbname": "barong_production",
    "database.hostname": "db",
    "database.password": "zsmartex",
    "database.server.name": "pg",
    "database.user": "zsmartex",
    "decimal.handling.mode": "double",
    "key.converter.schemas.enable": "true",
    "name": "pg-barong-connector",
    "slot.name": "barong_connector",
    "table.include.list": "public.activities,public.api_keys,public.profiles,public.attachments,public.users",
    "time.precision.mode": "connect",
    "transforms": "dropPrefix, filter",
    "transforms.dropPrefix.regex": "pg.public.(.*)",
    "transforms.dropPrefix.replacement": "pg.$1",
    "transforms.dropPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.filter.filter.condition": "$[?(@.op != 'c' && @.op != 'r' && @.source.table == 'activities')]",
    "transforms.filter.filter.type": "include",
    "transforms.filter.type": "io.confluent.connect.transforms.Filter$Value",
    "value.converter.schemas.enable": "true"
}
```

Peatio database connector:
```json
{
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.dbname": "peatio_production",
    "database.hostname": "db",
    "database.password": "zsmartex",
    "database.server.name": "pg",
    "database.user": "zsmartex",
    "decimal.handling.mode": "double",
    "key.converter.schemas.enable": "true",
    "name": "pg-peatio-connector",
    "slot.name": "peatio_connector",
    "table.include.list": "public.trades,public.orders,public.deposits,public.withdraws,public.beneficiaries,public.commissions,public.invite_links,public.asset_statistics,public.pnl_statistics,public.operations_assets,public.operations_expenses,public.operations_liabilities,public.operations_revenues",
    "time.precision.mode": "connect",
    "transforms": "dropPrefix, filter",
    "transforms.dropPrefix.regex": "pg.public.(.*)",
    "transforms.dropPrefix.replacement": "pg.$1",
    "transforms.dropPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.filter.filter.condition": "$[?(@.op != 'c' && @.op != 'r' && @.source.table in ['operations_assets', 'operations_expenses', 'operations_liabilities', 'operations_revenues', 'trades'])]",
    "transforms.filter.filter.type": "exclude",
    "transforms.filter.type": "io.confluent.connect.transforms.Filter$Value",
    "value.converter.schemas.enable": "true"
}
```

Elasticsearch orders sink:
```json
{
    "behavior.on.null.values": "DELETE",
    "connection.url": "http://elasticsearch:9200",
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "key.converter.schemas.enable": "true",
    "key.ignore": "false",
    "name": "es-orders-sink",
    "schema.ignore": "true",
    "tasks.max": "20",
    "topics": "pg.orders",
    "transforms": "unwrap,extractKey,triggeredAtTimestampConverter,createdAtTimestampConverter,updatedAtTimestampConverter",
    "transforms.createdAtTimestampConverter.field": "created_at",
    "transforms.createdAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.createdAtTimestampConverter.target.type": "string",
    "transforms.createdAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.extractKey.field": "id",
    "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.triggeredAtTimestampConverter.field": "triggered_at",
    "transforms.triggeredAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.triggeredAtTimestampConverter.target.type": "string",
    "transforms.triggeredAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.updatedAtTimestampConverter.field": "updated_at",
    "transforms.updatedAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.updatedAtTimestampConverter.target.type": "string",
    "transforms.updatedAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "value.converter.schemas.enable": "true",
    "write.method": "UPSERT"
}
```

Elasticsearch data sink:
```json
{
    "behavior.on.null.values": "DELETE",
    "connection.url": "http://elasticsearch:9200",
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "key.converter.schemas.enable": "true",
    "key.ignore": "false",
    "name": "es-normal-sink",
    "schema.ignore": "true",
    "tasks.max": "20",
    "topics": "pg.trades,pg.deposit_addresses,pg.transactions,pg.beneficiaries,pg.users,pg.activities,pg.api_keys,pg.profiles,pg.attachments,pg.operations_assets,pg.operations_expenses,pg.operations_liabilities,pg.operations_revenues,,pg.commissions,pg.invite_links",
    "transforms": "unwrap,extractKey,createdAtTimestampConverter,updatedAtTimestampConverter",
    "transforms.createdAtTimestampConverter.field": "created_at",
    "transforms.createdAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.createdAtTimestampConverter.target.type": "string",
    "transforms.createdAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.extractKey.field": "id",
    "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.updatedAtTimestampConverter.field": "updated_at",
    "transforms.updatedAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.updatedAtTimestampConverter.target.type": "string",
    "transforms.updatedAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "value.converter.schemas.enable": "true",
    "write.method": "UPSERT"
}
```

QuestDB ILP sink:
```json
{
    "connector.class": "io.questdb.kafka.QuestDBSinkConnector",
    "host": "questdb:9009",
    "key.converter.schemas.enable": "true",
    "name": "questdb_ilp_sink",
    "tasks.max": "20",
    "timestamp.field.name": "created_at",
    "topics": "pg.trades, pg.activities,pg.operations_assets,pg.operations_expenses,pg.operations_liabilities,pg.operations_revenues",
    "transforms": "unwrap,dropPrefix, addPrefix, createdAtTimestampConverter, updatedAtTimestampConverter",
    "transforms.addPrefix.regex": ".*",
    "transforms.addPrefix.replacement": "$0",
    "transforms.addPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.createdAtTimestampConverter.field": "created_at",
    "transforms.createdAtTimestampConverter.format": "yyyy-MM-dd HH:mm:ss.SSS",
    "transforms.createdAtTimestampConverter.target.type": "unix",
    "transforms.createdAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.dropPrefix.regex": "pg.(.*)",
    "transforms.dropPrefix.replacement": "$1",
    "transforms.dropPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.updatedAtTimestampConverter.field": "updated_at",
    "transforms.updatedAtTimestampConverter.format": "yyyy-MM-dd HH:mm:ss.SSS",
    "transforms.updatedAtTimestampConverter.target.type": "Timestamp",
    "transforms.updatedAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "value.converter.schemas.enable": "true"
}
```

Elasticsearch deposits and withdraws sink:
```json
{
    "behavior.on.null.values": "DELETE",
    "connection.url": "http://elasticsearch:9200",
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "key.converter.schemas.enable": "true",
    "key.ignore": "false",
    "name": "es-deposits-withdraws-sink-rc1",
    "schema.ignore": "true",
    "tasks.max": "20",
    "topics": "pg.deposits,pg.withdraws",
    "transforms": "unwrap,extractKey,createdAtTimestampConverter,updatedAtTimestampConverter,completedAtTimestampConverter",
    "transforms.completedAtTimestampConverter.field": "completed_at",
    "transforms.completedAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.completedAtTimestampConverter.target.type": "string",
    "transforms.completedAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.createdAtTimestampConverter.field": "created_at",
    "transforms.createdAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.createdAtTimestampConverter.target.type": "string",
    "transforms.createdAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.extractKey.field": "id",
    "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.updatedAtTimestampConverter.field": "updated_at",
    "transforms.updatedAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.updatedAtTimestampConverter.target.type": "string",
    "transforms.updatedAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "value.converter.schemas.enable": "true",
    "write.method": "UPSERT"
}
```

Elasticsearch statistics sink:
```json
{
    "behavior.on.null.values": "DELETE",
    "connection.url": "http://elasticsearch:9200",
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "key.converter.schemas.enable": "true",
    "key.ignore": "false",
    "name": "es-asset_statistics-pnl_statistics-sink-rc1",
    "schema.ignore": "true",
    "tasks.max": "20",
    "topics": "pg.asset_statistics,pg.pnl_statistics",
    "transforms": "unwrap,extractKey,createdAtTimestampConverter,updatedAtTimestampConverter,recordedAtTimestampConverter",
    "transforms.createdAtTimestampConverter.field": "created_at",
    "transforms.createdAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.createdAtTimestampConverter.target.type": "string",
    "transforms.createdAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.extractKey.field": "id",
    "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.recordedAtTimestampConverter.field": "recorded_at",
    "transforms.recordedAtTimestampConverter.format": "yyyy-MM-dd",
    "transforms.recordedAtTimestampConverter.target.type": "string",
    "transforms.recordedAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.updatedAtTimestampConverter.field": "updated_at",
    "transforms.updatedAtTimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
    "transforms.updatedAtTimestampConverter.target.type": "string",
    "transforms.updatedAtTimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "value.converter.schemas.enable": "true",
    "write.method": "UPSERT"
}
```

#### 4.4 Setup QuestDB

Go to [QuestDB Console](http://www.app.local:9000) and create tables using SQL:

* Remember to change the `app.local` to your domain name
* For QuestDB Console you only can execute one SQL command per time

```sql
CREATE TABLE activities (
  id INT,
  user_id INT,
  target_uid SYMBOL CAPACITY 128 NOCACHE,
  category STRING,
  user_ip STRING,
  user_ip_country STRING,
  user_agent STRING,
  topic STRING,
  action STRING,
  result STRING,
  data STRING,
  device STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
TIMESTAMP(created_at)
PARTITION BY DAY;

CREATE TABLE trades (
  id INT,
  market_id SYMBOL CAPACITY 128 NOCACHE,
  price DOUBLE,
  amount DOUBLE,
  total DOUBLE,
  maker_order_id INT,
  taker_order_id INT,
  maker_id INT,
  taker_id INT,
  side STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
TIMESTAMP(created_at)
PARTITION BY DAY;

CREATE TABLE operations_assets(
  id INT,
  code INT,
  currency_id STRING,
  reference_type STRING,
  reference_id INT,
  debit DOUBLE,
  credit DOUBLE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
TIMESTAMP(created_at)
PARTITION BY DAY;

CREATE TABLE operations_expenses(
  id INT,
  code INT,
  currency_id STRING,
  reference_type STRING,
  reference_id INT,
  debit DOUBLE,
  credit DOUBLE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
TIMESTAMP(created_at)
PARTITION BY DAY;

CREATE TABLE operations_liabilities(
  id INT,
  code INT,
  currency_id STRING,
  member_id INT,
  reference_type STRING,
  reference_id INT,
  debit DOUBLE,
  credit DOUBLE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
TIMESTAMP(created_at)
PARTITION BY DAY;

CREATE TABLE operations_revenues(
  id INT,
  code INT,
  currency_id STRING,
  member_id INT,
  reference_type STRING,
  reference_id INT,
  debit DOUBLE,
  credit DOUBLE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
TIMESTAMP(created_at)
PARTITION BY DAY;
```

#### 4.5 Setup materialize

SOON

You can login on `www.app.local` with the following default users from seeds.yaml
```
Seeded users:
Email: business@zsmart.tech, password: aQ#QLbG48m@L
Email: admin@zsmart.tech, password: aQ#QLbG48m@L
Email: demo@zsmart.tech, password: aQ#QLbG48m@L
Email: test@zsmart.tech, password: aQ#QLbG48m@L
```
