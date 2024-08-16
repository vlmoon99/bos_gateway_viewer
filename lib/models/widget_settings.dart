part of "../bos_gateway_viewer.dart";

@immutable
class WidgetSettings {
  final String widgetSrc;
  final String widgetProps;
  const WidgetSettings({
    required this.widgetSrc,
    this.widgetProps = """'{}'""",
  });
}