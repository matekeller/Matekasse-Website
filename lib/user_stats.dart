import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
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
            child: Center(
                child: Container(
                    height: 500,
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
                            child: SfCartesianChart(
                                tooltipBehavior: TooltipBehavior(
                                    duration: 3000,
                                    enable: true,
                                    activationMode: ActivationMode.singleTap,
                                    builder: ((data, point, series, pointIndex,
                                        seriesIndex) {
                                      DateTime time = data as DateTime;
                                      return Container(
                                          width: 300,
                                          height: 250,
                                          child: ListView(
                                            children: [
                                              ListTile(
                                                  title: Text(
                                                DateFormat(
                                                  "E, dd.MM.yy",
                                                ).format(DateFormat(
                                                        "yyy-MM-dd HH:mm:ss")
                                                    .parse(
                                                        time.toString(), true)),
                                                style: TextStyle(
                                                    color: Colors.white),
                                              )),
                                              Divider(
                                                color: Colors.white,
                                              ),
                                              GridView(
                                                  shrinkWrap: true,
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 4),
                                                  children: [
                                                    for (Transaction transaction
                                                        in transactions.where((element) =>
                                                            DateTime(
                                                                element.date
                                                                    .toLocal()
                                                                    .year,
                                                                element.date
                                                                    .toLocal()
                                                                    .month,
                                                                element.date
                                                                    .toLocal()
                                                                    .day) ==
                                                            DateTime(
                                                                time.year,
                                                                time.month,
                                                                time.day)))
                                                      CachedNetworkImage(
                                                          imageUrl: LocalStore
                                                              .offerings
                                                              .firstWhere((element) =>
                                                                  element
                                                                      .name ==
                                                                  transaction
                                                                      .offeringName)
                                                              .imageUrl,
                                                          placeholder: (context,
                                                                  url) =>
                                                              const CircularProgressIndicator()),
                                                  ])
                                            ],
                                          ));
                                    })),
                                zoomPanBehavior: ZoomPanBehavior(
                                    enablePinching: true, enablePanning: true),
                                primaryXAxis: DateTimeAxis(
                                    labelRotation: 270,
                                    enableAutoIntervalOnZooming: true,
                                    intervalType: DateTimeIntervalType.days),
                                primaryYAxis: NumericAxis(
                                    desiredIntervals: 1,
                                    title: AxisTitle(text: "#Mate"),
                                    maximum: 10),
                                series: <ChartSeries>[
                                  LineSeries<DateTime, DateTime>(
                                    dataSource: () {
                                      return List.generate(
                                          DateTime.now()
                                              .difference(transactions.last.date
                                                  .toLocal())
                                              .inDays,
                                          (i) => DateTime(
                                                  transactions.last.date
                                                      .toLocal()
                                                      .year,
                                                  transactions.last.date
                                                      .toLocal()
                                                      .month,
                                                  transactions.last.date
                                                      .toLocal()
                                                      .day)
                                              .add(Duration(days: i)));
                                    }(),
                                    xValueMapper: (DateTime time, _) => time,
                                    yValueMapper: (DateTime time, _) {
                                      int sum = 0;

                                      for (Transaction trans in transactions) {
                                        if (DateTime(
                                                trans.date.toLocal().year,
                                                trans.date.toLocal().month,
                                                trans.date.toLocal().day) ==
                                            DateTime(time.year, time.month,
                                                time.day)) {
                                          sum++;
                                        }
                                      }
                                      return sum;
                                    },
                                    dataLabelSettings: const DataLabelSettings(
                                        isVisible: true,
                                        alignment: ChartAlignment.center,
                                        labelAlignment:
                                            ChartDataLabelAlignment.top,
                                        showZeroValue: false),
                                  )
                                ]),
                          )
                        : (snapshot.hasError
                            ? Center(
                                child: Text("There was an error.\n" +
                                    snapshot.error.toString()))
                            : const Center(
                                child: CircularProgressIndicator(),
                              )))),
          ));
    });
  }
}
