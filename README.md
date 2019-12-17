# Load Generator

## Build

```bash
$ docker build -t koduki/loadgen -f dockerfiles/Dockerfile.loadgen .
```

## Run by Docker

```bash
$ docker run -it --network rc-isucon_default --rm -v $(pwd):/app koduki/loadgen bash
```

## Run

```bash
# Local Log
MIX_ENV=dev iex -S mix

# GCP Log
LOG_TYPE=GCP GCP_PRJ_ID=${YOUR_GCP_PROJECT} MIX_ENV=dev iex -S mix
```

## Show TPS

```bash
$ ruby ./tail_tps.rb loadgen.log
time: 2019-11-26T07:40:10	tps: 8	response(ms):21
time: 2019-11-26T07:40:11	tps: 3	response(ms):10
time: 2019-11-26T07:40:12	tps: 10	response(ms):12
```

## Dev

```bash
$ mix deps.get
$ MIX_ENV=dev iex -S mix
iex(1)> LoadGenerator.App.run(3,10)
```