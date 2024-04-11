import 'dart:developer';
import 'package:bos_gateway_viewer/bos_gateway_viewer.dart';
import 'package:example/near_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutterchain/flutterchain_lib/services/core/lib_initialization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFlutterChainLib();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      routes: {
        '/': (context) => const HomeScreen(),
        BosGatewatWidgetPreviewScreen.routeName: (context) =>
            const BosGatewatWidgetPreviewScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> widgetSettings = {"network": NearNetwork.mainnet};

  bool generateFucntionalKeyLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Init Screen'),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      const Text("Widget settings",
                          style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: "vlmoon.near/widget/ProfileEditor",
                        decoration: inputDecoration('Widget src'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter widget src';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          widgetSettings["widgetSrc"] = newValue!;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue: '{}',
                        decoration: inputDecoration("Widget props"),
                        onSaved: (newValue) {
                          final widgetPropsEncoded = """'$newValue'""";
                          widgetSettings["widgetProps"] = widgetPropsEncoded;
                        },
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Near account (can be empty if you want anonymous auth)",
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Network type",
                              style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          DropdownButton<NearNetwork>(
                            value: widgetSettings["network"],
                            items: NearNetwork.values
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e.name),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                widgetSettings["network"] = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue: "bosmobile.near",
                        decoration: inputDecoration("accountId"),
                        onSaved: (newValue) {
                          widgetSettings["accountId"] = newValue;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue:
                            "ed25519:5tbP6myFeFztTaCk25E8XkXeMvmxeUL9T4cJppKhSnFJsPA9NYBzPhu9eNMCVC9KBhTkKk6s8bGyGG28dUczSJ7v",
                        decoration: inputDecoration("privateKey"),
                        onSaved: (newValue) {
                          widgetSettings["privateKey"] = newValue;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue: "1",
                        decoration: inputDecoration("Near amount allowance"),
                        keyboardType: TextInputType.number,
                        onSaved: (newValue) {
                          widgetSettings["allowance"] = newValue;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (!generateFucntionalKeyLoading)
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      if (widgetSettings["privateKey"] != "" &&
                          widgetSettings["accountId"] != "" &&
                          widgetSettings["allowance"] != "") {
                        final NearVM nearVM = NearVM();
                        setState(() {
                          generateFucntionalKeyLoading = true;
                        });
                        final functionalPrivateKey =
                            await nearVM.getFunctionalKeyForNearSocial(
                          network:
                              (widgetSettings["network"] as NearNetwork).name,
                          accountId: widgetSettings["accountId"],
                          privateKey: widgetSettings["privateKey"],
                          allowance: widgetSettings["allowance"],
                        );

                        log("privateKey: ${widgetSettings["privateKey"]}");
                        log("functionalPrivateKey: $functionalPrivateKey");

                        widgetSettings["privateKey"] = functionalPrivateKey;

                        setState(() {
                          generateFucntionalKeyLoading = false;
                        });
                      }
                      Navigator.of(context).pushNamed(
                        BosGatewatWidgetPreviewScreen.routeName,
                        arguments: widgetSettings,
                      );
                    }
                  },
                  child: const Text("Open BosGatewayWidget"),
                )
              else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String labelText) {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: const OutlineInputBorder(),
      labelText: labelText,
      labelStyle: const TextStyle(fontSize: 20),
    );
  }
}

class BosGatewatWidgetPreviewScreen extends StatelessWidget {
  const BosGatewatWidgetPreviewScreen({super.key});

  static const routeName = '/bos_gateway_widget_preview_screen';

  @override
  Widget build(BuildContext context) {
    final bosGatewaySettings =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
        appBar: AppBar(
          title: const Text('BosGatewayWidgetPreview'),
        ),
        body: BosGatewayWidget(
          nearAuthCreds: NearAuthCreds(
            network: bosGatewaySettings["network"],
            accountId: bosGatewaySettings["accountId"],
            privateKey: bosGatewaySettings["privateKey"],
          ),
          widgetSettings: WidgetSettings(
            widgetSrc: bosGatewaySettings["widgetSrc"],
            widgetProps: bosGatewaySettings["widgetProps"],
          ),
        )
        // body: BosGatewayWidget(
        //   nearAuthCreds: NearAuthCreds(
        //     network: NearNetwork.mainnet,
        //     accountId: "bosmobile.near",
        //     privateKey:
        //         "ed25519:5tbP6myFeFztTaCk25E8XkXeMvmxeUL9T4cJppKhSnFJsPA9NYBzPhu9eNMCVC9KBhTkKk6s8bGyGG28dUczSJ7v",
        //   ),
        //   widgetSettings: WidgetSettings(
        //     widgetSrc: "contribut3.near/widget/IpfsFilesUpload",
        //     widgetProps: "{}",
        //   ),
        // ),
        );
  }
}
