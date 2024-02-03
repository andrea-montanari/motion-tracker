import 'package:flutter/material.dart';

class UserIdForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController textController;

  const UserIdForm({super.key, required this.formKey, required this.textController});

  @override
  UserIdFormState createState() {
    return UserIdFormState();
  }
}

class UserIdFormState extends State<UserIdForm>{
  static const String valueEmptyErrorMessage = "Please enter some text";
  static const String fewCharactersErrorMessage = "Please enter more than four characters";

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: widget.formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: widget.textController,

            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return valueEmptyErrorMessage;
              }
              if (value.length < 3) {
                return fewCharactersErrorMessage;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

}