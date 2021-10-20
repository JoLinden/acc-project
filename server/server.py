import flwr as fl
fl.server.start_server(config={'num_rounds': 3}, server_address='0.0.0.0:8080')
