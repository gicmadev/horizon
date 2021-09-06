# Horizon

To start your Phoenix server:

  * `docker-compose run --rm horizon mix local.hex --force`
  * `docker-compose run --rm horizon mix local.rebar --force`
  * `docker-compose run --rm horizon mix deps.get`
  * `docker-compose run --rm horizon mix do ecto.create, ecto.setup`
  * `docker-compose run --rm storybook yarn`
  * `docker-compose up -d`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
