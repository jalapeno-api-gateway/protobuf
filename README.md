# protobuf

This repository contains all protobuf definitions for the Jalapeño API Gateway.

# generate client in python
* Install grpcio and grpc_tools 
* python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. **/*.proto
