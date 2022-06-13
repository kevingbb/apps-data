[Place Holder]


DROP TABLE IF EXISTS random_data;

CREATE TABLE random_data AS
SELECT s                    AS first_column,
   md5(random()::TEXT)      AS second_column,
   md5((random()/2)::TEXT)  AS third_column
FROM generate_series(1,500000) s;
## Provision a single PG DB with public access 





## Create the benchmark-operator 

git clone https://github.com/cloud-bulldozer/benchmark-operator
cd benchmark-operator
make deploy

kga -n benchmark-operator 


#create pgbench CR 
cd ..


# create in zone 1
## without pgbounce 
kaf pgbench_cr_zone1.yaml 
kgp -n benchmark-operator -o wide
kl -n benchmark-operator
