import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:matemate/transaction.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class UserStats extends StatefulWidget {
  final String username;
  const UserStats({Key? key, required this.username}) : super(key: key);

  @override
  State<UserStats> createState() => _UserStatsState();
}

class _UserStatsState extends State<UserStats> {
  List<Transaction> transactions = [];
  LinkedScrollControllerGroup _controllers = LinkedScrollControllerGroup();
  ScrollController _month = ScrollController();
  ScrollController _all = ScrollController();

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    _month = _controllers.addAndGet();
    _all = _controllers.addAndGet();
  }

  @override
  void dispose() {
    _month.dispose();
    _all.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: () async {
      transactions = await GraphQlHelper.getTransactionListByUser(
          username: widget.username);

      transactions = transactions
          .where((element) =>
              (!element.deleted && element.offeringName != "topup"))
          .toList();
      return transactions;
    }(), builder: (context, snapshot) {
      return Scaffold(
          appBar: AppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.amber,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
            foregroundColor: Colors.white,
            title: Text("Statistics of ${widget.username}"),
            iconTheme: IconTheme.of(context),
          ),
          body: SafeArea(
            child: Column(children: [
              Flexible(
                  child: ListView(children: [
                SizedBox(
                    height: 300,
                    child: snapshot.hasData
                        ? RefreshIndicator(
                            onRefresh: () async {
                              transactions =
                                  await GraphQlHelper.getTransactionListByUser(
                                      username: widget.username);
                              transactions = transactions
                                  .where((element) => (!element.deleted &&
                                      element.offeringName != "topup"))
                                  .toList();
                              setState(() {});
                            },
                            child: UserChart(transactions: transactions),
                          )
                        : (snapshot.hasError
                            ? Center(
                                child: Text("There was an error.\n" +
                                    snapshot.error.toString()))
                            : const Center(
                                child: CircularProgressIndicator(),
                              ))),
                const Divider(),
              ])),
              Expanded(
                  child: DoubleList(
                      month: _month, transactions: transactions, all: _all))
            ]),
          ));
    });
  }
}

class DoubleList extends StatelessWidget {
  const DoubleList({
    Key? key,
    required ScrollController month,
    required this.transactions,
    required ScrollController all,
  })  : _month = month,
        _all = all,
        super(key: key);

  final ScrollController _month;
  final List<Transaction> transactions;
  final ScrollController _all;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: ListView(
          controller: _month,
          children: [
            const ListTile(
              title: Text(
                "This month:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (Offering offering in LocalStore.offerings
                .where((element) => element.name != "topup"))
              ListTile(
                contentPadding: const EdgeInsets.all(4.0),
                leading: CachedNetworkImage(
                  imageUrl: offering.imageUrl,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                ),
                title: Text("× " +
                    transactions
                        .where((element) =>
                            element.offeringName == offering.name &&
                            DateTime(element.date.toLocal().year,
                                    element.date.toLocal().month) ==
                                DateTime(
                                    DateTime.now().year, DateTime.now().month))
                        .length
                        .toString()),
              ),
            const Divider(),
            ListTile(
                leading: const Icon(FontAwesomeIcons.euroSign),
                title: Text(NumberFormat.currency(
                        locale: "de_DE",
                        symbol: "€",
                        customPattern: '#,##0.00\u00A4')
                    .format(transactions
                            .where((element) =>
                                DateTime(element.date.toLocal().year,
                                    element.date.toLocal().month) ==
                                DateTime(
                                    DateTime.now().year, DateTime.now().month))
                            .fold(0, (previousValue, element) {
                          int prevCents = previousValue as int;
                          return prevCents + element.pricePaidCents;
                        }).toDouble() /
                        100)))
          ],
        )),
        const VerticalDivider(),
        Expanded(
            child: ListView(
          controller: _all,
          children: [
            const ListTile(
              title: Text(
                "Overall:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (Offering offering in LocalStore.offerings
                .where((element) => element.name != "topup"))
              ListTile(
                contentPadding: const EdgeInsets.all(4.0),
                title: Text("× " +
                    transactions
                        .where(
                            (element) => element.offeringName == offering.name)
                        .length
                        .toString()),
              ),
            const Divider(),
            ListTile(
                title: Text(NumberFormat.currency(
                        locale: "de_DE",
                        symbol: "€",
                        customPattern: '#,##0.00\u00A4')
                    .format(transactions.fold(0, (previousValue, element) {
                          int prevCents = previousValue as int;
                          return prevCents + element.pricePaidCents;
                        }).toDouble() /
                        100)))
          ],
        ))
      ],
    );
  }
}

class UserChart extends StatelessWidget {
  const UserChart({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
        tooltipBehavior: TooltipBehavior(
            duration: 3000,
            enable: true,
            activationMode: ActivationMode.singleTap,
            builder: ((data, point, series, pointIndex, seriesIndex) {
              DateTime time = data as DateTime;
              return SizedBox(
                  width: 300,
                  height: 250,
                  child: ListView(
                    children: [
                      ListTile(
                          title: Text(
                        DateFormat(
                          "E, dd.MM.yy",
                        ).format(DateFormat("yyy-MM-dd HH:mm:ss")
                            .parse(time.toString(), true)),
                        style: const TextStyle(color: Colors.white),
                      )),
                      const Divider(
                        color: Colors.white,
                      ),
                      GridView(
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4),
                          children: [
                            for (Transaction transaction in transactions.where(
                                (element) =>
                                    DateTime(
                                        element.date.toLocal().year,
                                        element.date.toLocal().month,
                                        element.date.toLocal().day) ==
                                    DateTime(time.year, time.month, time.day)))
                              CachedNetworkImage(
                                  imageUrl: LocalStore.offerings
                                      .firstWhere((element) =>
                                          element.name ==
                                          transaction.offeringName)
                                      .imageUrl,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator()),
                          ])
                    ],
                  ));
            })),
        zoomPanBehavior:
            ZoomPanBehavior(enablePinching: true, enablePanning: true),
        primaryXAxis: DateTimeAxis(
            labelRotation: 270,
            enableAutoIntervalOnZooming: true,
            intervalType: DateTimeIntervalType.days),
        primaryYAxis: NumericAxis(
            anchorRangeToVisiblePoints: false,
            desiredIntervals: 1,
            title: AxisTitle(text: "#Mate"),
            maximum: 10),
        series: <ChartSeries>[
          LineSeries<DateTime, DateTime>(
            dataSource: () {
              return List.generate(
                  DateTime.now()
                      .difference(transactions.last.date.toLocal())
                      .inDays,
                  (i) => DateTime(
                          transactions.last.date.toLocal().year,
                          transactions.last.date.toLocal().month,
                          transactions.last.date.toLocal().day)
                      .add(Duration(days: i)));
            }(),
            xValueMapper: (DateTime time, _) => time,
            yValueMapper: (DateTime time, _) {
              int sum = 0;

              for (Transaction trans in transactions) {
                if (DateTime(trans.date.toLocal().year,
                        trans.date.toLocal().month, trans.date.toLocal().day) ==
                    DateTime(time.year, time.month, time.day)) {
                  sum++;
                }
              }
              return sum;
            },
            dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                alignment: ChartAlignment.center,
                labelAlignment: ChartDataLabelAlignment.top,
                showZeroValue: false),
          )
        ]);
  }
}
