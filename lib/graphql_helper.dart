import 'dart:convert';
import 'dart:io';
import 'package:matemate/inventory.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/transaction.dart';
import 'package:http/http.dart' as http;
import 'package:matemate/user_list.dart';

import 'offering.dart';

class GraphQlHelper {
  /// Uses the given username and password to sign the user in
  static Future<void> signIn(username, password) async {
    var headers = {'Content-Type': 'application/json'};
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation {\\n  signIn(username: \\"$username\\", password: \\"$password\\")\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      dynamic response =
          jsonDecode(await (streamedResponse.stream.bytesToString()));
      if (response['data'] == null) {
        if (response['errors'] == null) {
          throw Exception("Request succeded, no data, but no errors");
        } else {
          if (response['errors'][0]['message'] == "Invalid credentials") {
            throw InvalidSignInCredentialsException();
          }
          if (response['errors'][0]['message'] ==
              "no rows returned by a query that expected to return at least one row") {
            throw InvalidSignInCredentialsException();
          }
        }
      } else {
        String newAuthToken = response['data']['signIn'];
        LocalStore.authToken = newAuthToken;
        return;
      }
    } else if (streamedResponse.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(streamedResponse.reasonPhrase.toString() +
          " StatusCode: " +
          streamedResponse.statusCode.toString());
    }
  }

  static int _currentCursor = 0;
  static bool hasNextPage = true;

  /// Returns the highest cursor that the paginated transactions can habe
  static Future<int> getEndCursor() async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"query {\\n    transactionsPaginated(first: 0, after: 0) {\\n        pageInfo {\\n            endCursor\\n        }\\n    }\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return jsonDecode(await response.stream.bytesToString())["data"]
          ["transactionsPaginated"]["pageInfo"]["endCursor"];
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  /// Returns a list containing the transactions from the server, that have a cursor
  /// between [_currentCursor]- 10 and [_currentCursor]
  static Future<List<Transaction>> getTransactionList(
      {bool fromBeginning = false, int after = 0, int first = 10}) async {
    // If we start from the beginning, we will start at the highest cursor +1
    // but if we have no transactions this would fail. This is why we take the highest
    // cursor here
    if (fromBeginning) {
      _currentCursor = await getEndCursor();
      hasNextPage = true;
    } else {
      _currentCursor = after;
    }
    // Check if it is 0 here, and if yes append the empty list
    if (_currentCursor == 0) {
      hasNextPage = false;
      return [];
    }
    // And then increment the current cursor.
    if (fromBeginning) {
      _currentCursor++;
    }
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"query {\\n    transactionsPaginated(first: $first, after: $_currentCursor) {\\n        edges {\\n            node {\\n                admin {\\n                    username\\n                }\\n                offeringId\\n                payer {\\n                    username\\n                #    bluecardId\\n                }\\n                pricePaidCents\\n                timestamp\\n            id\\n            deleted\\n}\\n            cursor\\n        }\\n        pageInfo {\\n            hasNextPage\\n            endCursor\\n        }\\n    }\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    String responseString = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      List<dynamic> transactionMaps =
          jsonDecode(responseString)['data']['transactionsPaginated']['edges'];
      List<Transaction> transactionsPage = [];

      for (dynamic transactionMap in transactionMaps) {
        String offeringId = transactionMap['node']['offeringId'];
        String adminUsername = transactionMap['node']['admin']['username'];
        String payerUsername = transactionMap['node']['payer']['username'];
        // double timestampSecondsSinceEpochFloat =
        //     transactionMap['node']['timestamp'];
        // int timestampSecondsSinceEpoch =
        //     timestampSecondsSinceEpochFloat.toInt();
        int pricePaidCents = transactionMap['node']['pricePaidCents'];
        DateTime parsedDate =
            DateTime.parse(transactionMap['node']['timestamp']);
        DateTime date = DateTime.utc(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
            parsedDate.millisecond,
            parsedDate.microsecond); // server is in UTC

        int transactionID = transactionMap['node']['id'];
        bool deleted = transactionMap['node']['deleted'];

        transactionsPage.add(Transaction(
            payerUsername: payerUsername,
            adminUsername: adminUsername,
            offeringName: offeringId,
            pricePaidCents: pricePaidCents,
            date: date,
            id: transactionID,
            deleted: deleted));
        _currentCursor = transactionMap['cursor'];
      }
      hasNextPage = jsonDecode(responseString)['data']['transactionsPaginated']
          ['pageInfo']['hasNextPage'];
      return transactionsPage;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    }

    throw Exception(response.reasonPhrase);
  }

  static Future<List<Transaction>> getTransactionListByUser(
      {required String username}) async {
    hasNextPage = false;

    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"query {\\n    transactionsByUser(username: \\"$username\\") {\\n        admin{username}\\n      offeringId\\n      timestamp\\n      pricePaidCents\\n            id\\n            deleted\\n}\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    String responseString = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      List<dynamic> transactionMaps =
          jsonDecode(responseString)['data']['transactionsByUser'];
      List<Transaction> transaction = [];

      for (dynamic transactionMap in transactionMaps) {
        String offeringId = transactionMap['offeringId'];
        String adminUsername = transactionMap['admin']['username'];
        String payerUsername = username;
        int pricePaidCents = transactionMap['pricePaidCents'];
        DateTime parsedDate = DateTime.parse(transactionMap['timestamp']);

        DateTime date = DateTime.utc(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
            parsedDate.millisecond,
            parsedDate.microsecond); // server is in UTC

        int transactionID = transactionMap['id'];
        bool deleted = transactionMap['deleted'];

        transaction.add(Transaction(
            payerUsername: payerUsername,
            adminUsername: adminUsername,
            offeringName: offeringId,
            pricePaidCents: pricePaidCents,
            date: date,
            id: transactionID,
            deleted: deleted));
      }

      return transaction;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    }

    throw Exception(response.reasonPhrase);
  }

  static Future<List<User>> updateAllUsers() async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"query {\\n  users {\\n      balance\\n      fullName\\n      username\\n      bluecardId\\n      smartcards {      smartcardId\\n}\\n  isAdmin     }\\n}\\n\\n","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      dynamic usersJson =
          jsonDecode(await response.stream.bytesToString())["data"]["users"];
      LocalStore.allUsersJson = jsonEncode(usersJson);
      List<User> users = [];
      for (dynamic userJson in usersJson) {
        //print(userJson['smartcards']);
        List<String> smartcardList = [];

        for (dynamic smartcard in userJson['smartcards']) {
          smartcardList.add(smartcard['smartcardId']);
        }

        users.add(
          User(
              balanceCents: userJson['balance'] ?? 0,
              fullName: userJson['fullName'],
              username: userJson['username'],
              bluecardId: userJson['bluecardId'],
              smartcards: smartcardList,
              isAdmin: userJson['isAdmin']),
        );
      }
      return users;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  //Sends a purchase request to the server
  static Future<bool> purchaseProduct(
      String username, String offeringID) async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation {\\n  purchase(product: \\"$offeringID\\", payer: \\"$username\\")\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  static Future<bool> undoPurchase(int transactionID) async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation {\\n  undoPurchase(transactionId: $transactionID)\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  static Future<bool> purchaseMultipleProducts(
      String username, List<String> offeringIDs) async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var products = "";
    int count = 1;
    for (String id in offeringIDs) {
      products +=
          '''\\n purchase$count: purchase(product: \\"$id\\", payer: \\"$username\\")''';
      count++;
    }
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation BuyMultiple {$products \\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  ///Sends a topup request with the given username and ammount of €
  static Future<bool> topUp(String username, int ammount) async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation {\\n  topup(payer: \\"$username\\", amountCents: $ammount)\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  ///Sends a topup request with the given username and ammount of €
  static Future<bool> updateBluecardId(
      String oldBluecardId, String newBluecardId) async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation {\\n  updateBluecardId(bluecardIdOld: \\"$oldBluecardId\\", bluecardIdNew: \\"$newBluecardId\\")\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  static Future<bool> addSmartCardToUser(
      String username, String smartCardID) async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation {\\n  addSmartcardToUser(username: \\"$username\\", smartcardId: \\"$smartCardID\\")\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  //Adds a new user to the Database
  static Future<bool> addUser(username, fullName, password, bluecardId) async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"mutation {\\n  register(username: \\"$username\\", fullName: \\"$fullName\\", password: \\"$password\\", bluecardId: \\"$bluecardId\\")\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    }
    return false;
  }

  /// Updates the offerings
  static Future<void> updateOfferings() async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"query {\\n  offerings {\\n      name\\n      readableName\\n      priceCents\\n      imageUrl\\n    color\\n}\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      List<dynamic> offerings =
          jsonDecode(await response.stream.bytesToString())['data']
              ['offerings'];

      List<Offering> newOfferings = [
        for (dynamic offering in offerings)
          Offering(
              name: offering['name'],
              readableName: offering['readableName'],
              priceCents: offering['priceCents'],
              imageUrl: offering['imageUrl'] ?? "",
              color: int.parse(
                  "FF${offering['color'].toString().replaceFirst("#", "").toUpperCase()}",
                  radix: 16))
      ];

      LocalStore.offerings = newOfferings;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception("An error Occured");
    }
  }

  ///returns a username by the bluecard ID
  static String? getUsernameByBluecardId(String bluecardID) {
    List<dynamic> users = jsonDecode(LocalStore.allUsersJson);
    String? username = users.firstWhere(
        (user) => user["bluecardId"] == bluecardID,
        orElse: () => {"username": null})["username"];
    return username;
  }

  /// Returns whether a user already exists in the database or not
  static bool userExists(String username) {
    List<dynamic> users = jsonDecode(LocalStore.allUsersJson);
    return users.firstWhere((user) => user["username"] == username,
            orElse: () => null) !=
        null;
  }

  static Future<List<InventoryItem>> getInventory() async {
    String authToken = LocalStore.authToken;
    List<InventoryItem> inventory = [];
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };

    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query":"query {\\n    inventory{\\n      offeringId\\n      amount\\n}\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    String responseString = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      List<dynamic> inventoryMaps =
          jsonDecode(responseString)['data']['inventory'];

      for (dynamic inventoryItem in inventoryMaps) {
        String offeringId = inventoryItem['offeringId'];
        int amount = inventoryItem['amount'];

        inventory.add(InventoryItem(offeringID: offeringId, amount: amount));
      }

      return inventory;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    }

    throw Exception(response.reasonPhrase);
  }

  static Future<bool> updateInventory(List<InventoryItem> changes) async {
    String authToken = LocalStore.authToken;
    List parsedChanges = changes
        .map((e) =>
            {"offeringId": "\\\"" + e.offeringID + "\\\"", "amount": e.amount})
        .toList();

    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };

    var request =
        http.Request('POST', Uri.parse('https://matekasse.gero.dev/graphql'));
    request.body =
        '''{"query": "mutation { updateInventory(updates: $parsedChanges) }"}''';

    request.headers.addAll(headers);

    http.StreamedResponse streamedResponse = await request.send();

    //print(streamedResponse.reasonPhrase);

    if (streamedResponse.statusCode == 200) {
      dynamic response =
          jsonDecode(await (streamedResponse.stream.bytesToString()));

      if (response["data"]["updateInventory"] == "updated") {
        return true;
      }

      return false;
    } else if (streamedResponse.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(streamedResponse.reasonPhrase);
    }
  }
}

class InvalidSignInCredentialsException implements Exception {}
