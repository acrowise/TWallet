import 'package:get/get.dart';
import 'package:http/http.dart' show Client;
import 'package:optional/optional.dart';
import 'package:tw_wallet_ui/service/api_provider.dart';
import 'package:tw_wallet_ui/service/blockchain.dart';
import 'package:tw_wallet_ui/store/env_store.dart';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const maxGas = 300000;
const contractsOnChain = ['token', 'identities'];

class ContractService {
  const ContractService(this.contracts);

  final Map<String, Contract> contracts;

  Contract get tokenContract => contracts[contractsOnChain[0]];

  Contract get identitiesContract => contracts[contractsOnChain[1]];

  static Future<ContractService> init() async {
    final Map<String, Contract> contracts = {};
    for (final name in contractsOnChain) {
      (await Contract.fromApi(name))
          .ifPresent((contract) => contracts[name] = contract);
    }
    return ContractService(contracts);
  }
}

class Contract {
  Contract(this.contract);

  final DeployedContract contract;
  final Web3Client web3Client =
      Web3Client(globalEnv().web3RpcGatewayUrl, Client());

  static Future<Optional<Contract>> fromApi(String contractName) async {
    return Get.find<ApiProvider>()
        .fetchContractAbiV1(contractName: contractName)
        .then((res) {
      res.ifPresent((contract) {
        if (contractName == contractsOnChain[0]) {
          globalEnv().rebuild((builder) {
            builder.tokenName = contract.name;
            if (null != contract.symbol) {
              builder.tokenSymbol = contract.symbol;
            }
            if (null != contract.decimal) {
              builder.tokenPrecision = contract.decimal;
            }
            Get.find<EnvStore>().env = builder.build();
          });
        }
      });

      return res.map((contract) => Contract(DeployedContract(
          ContractAbi.fromJson(contract.abi, contractName),
          EthereumAddress.fromHex(contract.address))));
    });
  }

  Transaction makeTransaction(String functionName, List<dynamic> parameters) {
    return Transaction.callContract(
      contract: contract,
      function: contract.function(functionName),
      parameters: parameters,
      gasPrice: EtherAmount.zero(),
      maxGas: maxGas,
    );
  }

  Future<List<dynamic>> callFunction(
      String publicKey, String functionName, List<dynamic> parameters) async {
    return web3Client
        .call(
            sender: EthereumAddress.fromHex(
                BlockChainService.publicKeyToAddress(publicKey.substring(2))),
            contract: contract,
            function: contract.function(functionName),
            params: parameters ?? [])
        .then((res) {
      return res;
    });
  }

  Future<bool> sendTransaction(
      String privateKey, String functionName, List<dynamic> parameters) async {
    TransactionReceipt receipt;
    final String hash = await web3Client
        .credentialsFromPrivateKey(privateKey)
        .then((credentials) => web3Client.sendTransaction(
            credentials, makeTransaction(functionName, parameters ?? []),
            fetchChainIdFromNetworkId: true));

    while (true) {
      await Future.delayed(const Duration(seconds: 2)).then((_) async {
        receipt = await web3Client.getTransactionReceipt(hash);
      });

      if (receipt != null) {
        break;
      }
    }

    return receipt.status;
  }

  Future<String> signContractCall(
      String privateKey, String functionName, List<dynamic> parameters) async {
    return web3Client.credentialsFromPrivateKey(privateKey).then((credentials) {
      return web3Client
          .signTransaction(
              credentials, makeTransaction(functionName, parameters),
              fetchChainIdFromNetworkId: true)
          .then((rawTx) => '0x${bytesToHex(rawTx)}');
    });
  }
}