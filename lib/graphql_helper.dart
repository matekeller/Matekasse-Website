import 'dart:convert';
import 'dart:io';
import 'package:matemate/local_store.dart';
import 'package:matemate/transaction.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

import 'offering.dart';
import 'user.dart';

class GraphQlHelper {
  /// Uses the given username and password to sign the user in
  static Future<void> signIn(username, password) async {
    var headers = {'Content-Type': 'application/json'};
    var request =
        http.Request('POST', Uri.parse('https://api.matekasse.de/graphql'));
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
        http.Request('POST', Uri.parse('https://api.matekasse.de/graphql'));
    // NOTE: Backend does weird things when quering with "first: 0", I suppose it replies with the total number of a users transactions
    request.body =
        '''{"query":"query {\\n    me { transactionsPaginated(first: 1, after: 100000) {\\n        pageInfo {\\n            endCursor\\n        }\\n    }\\n }\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return jsonDecode(await response.stream.bytesToString())["data"]["me"]
              ["transactionsPaginated"]["pageInfo"]["endCursor"] +
          1;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception(response.reasonPhrase);
    }
  }

  static Future<User> getMyself() async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };

    var request =
        http.Request('POST', Uri.parse('https://api.matekasse.de/graphql'));
    // NOTE: Backend does weird things when quering with "first: 0", I suppose it replies with the total number of a users transactions
    request.body =
        '''{"query":"query {\\n  me {\\n    fullName\\n    username\\n    bluecardId\\n    isAdmin\\n    smartcards {\\n      smartcardId\\n    }\\n    balance\\n    \\n  }\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var userJson =
          jsonDecode(await response.stream.bytesToString())["data"]["me"];

      List<String> smartcardList = [];

      for (dynamic smartcard in userJson['smartcards']) {
        smartcardList.add(smartcard['smartcardId']);
      }

      LocalStore.myUser = User(
          balanceCents: userJson['balance'] ?? 0,
          fullName: userJson['fullName'],
          username: userJson['username'],
          bluecardId: userJson['bluecardId'],
          smartcards: smartcardList,
          isAdmin: userJson['isAdmin']);

      return User(
          balanceCents: userJson['balance'] ?? 0,
          fullName: userJson['fullName'],
          username: userJson['username'],
          bluecardId: userJson['bluecardId'],
          smartcards: smartcardList,
          isAdmin: userJson['isAdmin']);
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      var userJson =
          jsonDecode(await response.stream.bytesToString())["errors"];
      print(userJson);
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
        http.Request('POST', Uri.parse('https://api.matekasse.de/graphql'));
    request.body =
        '''{"query":"query {\\n    me{\\n    transactionsPaginated(first: $first, after: $_currentCursor) {\\n        edges {\\n            node {\\n                admin {\\n                    username\\n                }\\n                offeringId\\n                payer {\\n                    username\\n                #    bluecardId\\n                }\\n                pricePaidCents\\n                timestamp\\n            id\\n            deleted\\n}\\n            cursor\\n        }\\n        pageInfo {\\n            hasNextPage\\n            endCursor\\n        }\\n    }\\n    }\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    String responseString = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      List<dynamic> transactionMaps = jsonDecode(responseString)['data']['me']
          ['transactionsPaginated']['edges'];

      _currentCursor = jsonDecode(responseString)['data']['me']
          ['transactionsPaginated']['pageInfo']['endCursor'];
      List<Transaction> transactionsPage = [];

      transactionsPage = transactionMaps.fold([], (prev, element) {
        DateTime parsedDate = DateTime.parse(element['node']['timestamp']);
        DateTime date = DateTime.utc(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
            parsedDate.millisecond,
            parsedDate.microsecond);
        return prev
          ..add(Transaction(
              payerUsername: element['node']['payer']['username'],
              adminUsername: element['node']['admin']['username'],
              offeringName: element['node']['offeringId'],
              pricePaidCents: element['node']['pricePaidCents'],
              date: date,
              id: element['node']['id'],
              deleted: element['node']['deleted']));
      });

      _currentCursor = transactionMaps.last['cursor'];

      hasNextPage = jsonDecode(responseString)['data']['me']
          ['transactionsPaginated']['pageInfo']['hasNextPage'];
      return transactionsPage;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    }

    throw Exception(response.reasonPhrase);
  }

  /// Updates the offerings
  static Future<void> updateOfferings() async {
    String authToken = LocalStore.authToken;
    var headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://api.matekasse.de/graphql'));
    request.body =
        '''{"query":"query {\\n  offerings {\\n      name\\n      readableName\\n      priceCents\\n      imageUrl\\n    color\\n}\\n}","variables":{}}''';

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      List<dynamic> offerings =
          jsonDecode(await response.stream.bytesToString())['data']
              ['offerings'];

      List<Offering> newOfferings = offerings.fold(
          [],
          (prev, element) => prev
            ..add(Offering(
              name: element['name'],
              readableName: element['readableName'],
              priceCents: element['priceCents'],
              imageUrl: element['imageUrl'] ?? "",
              color: int.parse(
                  "FF${element['color'].toString().replaceFirst("#", "").toUpperCase()}",
                  radix: 16),
            )));

      LocalStore.offerings = newOfferings;
    } else if (response.statusCode == 404) {
      throw const SocketException("The Server is not online");
    } else {
      throw Exception("An error Occured");
    }
  }
}

class InvalidSignInCredentialsException implements Exception {}
