defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: [ "application/json", "application/vnd.api+json" ],
    html: [ "text/html", "application/xhtml+html" ],
    sparql: [ "application/sparql-results+json" ],
    any: [ "*/*" ]
  ]

  define_layers [ :static, :sparql, :frontend_fallback, :resources, :api_services, :not_found ]

  options "*path", _ do
    conn
    |> Plug.Conn.put_resp_header( "access-control-allow-headers", "content-type,accept" )
    |> Plug.Conn.put_resp_header( "access-control-allow-methods", "*" )
    |> send_resp( 200, "{ \"message\": \"ok\" }" )
  end

  ###############
  # STATIC
  ###############

  # self-service
  match "/index.html", %{ host: "*.harvesting-self-service.lblod.info", layer: :static } do
    forward conn, [], "http://frontend-harvesting-self-service/index.html"
  end

  get "/assets/*path",  %{ host: "*.harvesting-self-service.lblod.info", layer: :static } do
    forward conn, path, "http://frontend-harvesting-self-service/assets/"
  end

  get "/@appuniversum/*path", %{ host: "*.harvesting-self-service.lblod.info", layer: :static } do
    forward conn, path, "http://frontend-harvesting-self-service/@appuniversum/"
  end

  # frontend
  match "/assets/*path", %{ layer: :static } do
    forward conn, path, "http://frontend/assets/"
  end

  match "/index.html", %{ layer: :static } do
    forward conn, [], "http://frontend/index.html"
  end

  match "/favicon.ico", %{ layer: :static } do
    send_resp( conn, 404, "" )
  end

  ###############
  # SPARQL
  ###############
  match "/sparql", %{ layer: :sparql, accept: %{ html: true } } do
    forward conn, [], "http://frontend/sparql"
  end

  match "/sparql", %{ layer: :sparql, accept: %{ sparql: true } } do
    forward conn, [], "http://database:8890/sparql"
  end

  ###############
  # API SERVICES
  ###############
  match "/resource-labels/*path", %{ layer: :api_services, accept: %{ json: true } } do
    forward conn, path, "http://resource-labels/"
  end

  match "/uri-info/*path", %{ layer: :api_services, accept: %{ json: true } } do
    forward conn, path, "http://uri-info/"
  end

  #################
  # FRONTEND PAGES
  #################

  # self-service
  match "/*path", %{ host: "*.harvesting-self-service.lblod.info", layer: :frontend_fallback, accept: %{ html: true } } do
    # we don't forward the path, because the app should take care of this in the browser.
    forward conn, [], "http://frontend-harvesting-self-service/index.html"
  end

  match "/*path", %{ layer: :frontend_fallback, accept: %{ html: true } } do
    # We forward path for fastboot
    forward conn, path, "http://frontend/"
  end

  # match "/favicon.ico", @any do
  #   send_resp( conn, 404, "" )
  # end

  ###############
  # RESOURCES
  ###############

  match "/remote-data-objects/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/remote-data-objects/"
  end

  match "/harvesting-collections/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/harvesting-collections/"
  end

  match "/jobs/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/jobs/"
  end

  match "/tasks/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/tasks/"
  end

  match "/data-containers/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/data-containers/"
  end

  match "/job-errors/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/job-errors/"
  end

  get "/files/:id/download" do
    Proxy.forward conn, [], "http://file/files/" <> id <> "/download"
  end

  match "/files/*path" do
    Proxy.forward conn, path, "http://cache/files/"
  end

  get "/bestuurseenheden/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/bestuurseenheden/"
  end

  get "/werkingsgebieden/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/werkingsgebieden/"
  end
  get "/bestuurseenheid-classificatie-codes/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/bestuurseenheid-classificatie-codes/"
  end
  get "/bestuursorganen/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/bestuursorganen/"
  end
  get "/bestuursorgaan-classificatie-codes/*path", %{ layer: :resources, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/bestuursorgaan-classificatie-codes/"
  end

  #################
  # NOT FOUND
  #################
  match "/*_path", %{ layer: :not_found } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end

end
