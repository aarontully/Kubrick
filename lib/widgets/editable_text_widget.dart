import 'package:flutter/material.dart';
import 'package:kubrick/main.dart';

class EditableTextWidget extends StatefulWidget {
  final String initialText;
  final Function(String) onSubmitted;

  const EditableTextWidget({
    super.key,
    required this.initialText,
    required this.onSubmitted,
  });

  @override
  _EditableTextWidgetState createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditing = true;
          FocusScope.of(context).requestFocus(_focusNode);
        });
      },
      child: _isEditing ? _buildTextField() : _buildText(),
    );
  }

  Widget _buildText() {
    return Text(widget.initialText);
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      onFieldSubmitted: (value) {
        widget.onSubmitted(value);
        setState(() {
          _isEditing = false;
        });
      },
    );
  }
}
