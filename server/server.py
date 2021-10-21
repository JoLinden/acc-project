import flwr as fl
from config import n_clients

strategy = fl.server.strategy.FedAvg(min_fit_clients=n_clients,
                                     min_eval_clients=n_clients,
                                     min_available_clients=n_clients)
fl.server.start_server(config={'num_rounds': 3}, server_address='0.0.0.0:8080', strategy=strategy)
