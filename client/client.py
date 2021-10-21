import flwr as fl
import tensorflow as tf
import numpy as np
from config import server_ip, n_clients, client_id

(x_train, y_train), (x_test, y_test) = tf.keras.datasets.cifar10.load_data()
x_train = np.array_split(x_train, n_clients)[client_id]
y_train = np.array_split(y_train, n_clients)[client_id]

x_test = np.array_split(x_test, n_clients)[client_id]
y_test = np.array_split(y_test, n_clients)[client_id]

model = tf.keras.applications.MobileNetV2((32, 32, 3), classes=10, weights=None)
model.compile('adam', 'sparse_categorical_crossentropy', metrics=['accuracy'])


class CifarClient(fl.client.NumPyClient):
    def get_parameters(self):
        return model.get_weights()

    def fit(self, parameters, config):
        model.set_weights(parameters)
        model.fit(x_train, y_train, epochs=1, batch_size=1)
        return model.get_weights(), len(x_train), {}

    def evaluate(self, parameters, config):
        model.set_weights(parameters)
        loss, accuracy = model.evaluate(x_test, y_test)
        return loss, len(x_test), {'accuracy': accuracy}


fl.client.start_numpy_client(f'{server_ip}:8080', client=CifarClient())
