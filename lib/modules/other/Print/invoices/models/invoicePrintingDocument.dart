// ignore_for_file: file_names

import 'dart:async';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:test/modules/other/Print/invoices/views/invoice.dart';

const printingInvoiceDocument = <PrintDocument>[
  PrintDocument('Invoice', 'InvoiceDoc.dart', generateInvoice),
  PrintDocument('Invoice', 'PreviewInvoiceDoc.dart', generatePreviewInvoice),
];

typedef LayoutCallbackWithData = Future<Uint8List> Function(
    PdfPageFormat pageFormat, CustomData data);

class PrintDocument {
  const PrintDocument(this.data, this.file, this.builder,
      [this.needsData = false]);

  final String data;

  final String file;

  final LayoutCallbackWithData builder;

  final bool needsData;
}

class CustomData {
  const CustomData({this.data = 'Data here'});

  final String data;
}
