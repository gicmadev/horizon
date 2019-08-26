FROM elixir:1.9.1 as runner

VOLUME /var/run/.mix

EXPOSE 4000
ENV MIX_HOME=/var/run/.mix

WORKDIR /app

CMD ["mix", "phx.server"]

FROM runner as builder

ADD mix.exs .
ADD mix.lock .

ENV MIX_ENV prod

RUN mix local.rebar --force

RUN mix local.hex --if-missing --force

RUN mix deps.get --only prod

RUN mix deps.compile
ENV MIX_ENV prod
RUN mix local.hex --if-missing --force

WORKDIR /app

ADD . .
RUN mix compile
RUN mix release

ARG APP_NAME=horizon
RUN cp -vr _build/dev/rel/$APP_NAME /tmp/release;

# now run the release.  Make sure the alpine version below matches the alpine version
# included by erlang included by elixir:1.8-alpine
FROM alpine:3.9 as podcloud-horizon

RUN apk update && apk add --no-cache bash openssl

ENV MIX_ENV prod
ENV LANG C.UTF-8

COPY --from=builder /release /app

EXPOSE 80

ARG APP_NAME=horizon
ENTRYPOINT ["/app/bin/$APP_NAME", "start"]
