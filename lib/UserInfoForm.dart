import 'package:flutter/material.dart';

class UserInfoForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController idController;
  final TextEditingController ageController;
  final TextEditingController sexController;
  final TextEditingController heightController;
  final TextEditingController weightController;

  UserInfoForm({
    super.key,
    required this.formKey,
    required this.idController,
    required this.ageController,
    required this.sexController,
    required this.heightController,
    required this.weightController,
  });

  @override
  UserInfoFormState createState() {
    return UserInfoFormState();
  }
}

class UserInfoFormState extends State<UserInfoForm>{
  static const String userIdLabel = "ID number";
  static const String userAgeLabel = "Age";
  static const String userSexLabel = "Sex";
  static const String userHeightLabel = "Height (cm)";
  static const String userWeightLabel = "Weight (kg)";
  static const String valueEmptyErrorMessage = "This field is required";
  static const String notIntegerErrorMessage = "Please enter a non-negative whole number";
  static const String sexDropdownDefaultValue = "--";

  static const List sexList = ["--", "Female", "Male", "Intersex", "Prefer not to disclose"];

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    String sexDropdownValue = sexDropdownDefaultValue;

    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[

          // User ID
          TextFormField(
            controller: widget.idController,
            decoration: const InputDecoration(labelText: userIdLabel),
            keyboardType: TextInputType.number,

            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return valueEmptyErrorMessage;
              }
              try {
                var intId = int.parse(value);
                if (intId < 0) {
                  throw Exception;
                }
              } catch (e) {
                return notIntegerErrorMessage;
              }
              return null;
            },
          ),

          // User Age
          TextFormField(
            controller: widget.ageController,
            decoration: const InputDecoration(labelText: userAgeLabel),
            keyboardType: TextInputType.number,

            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return valueEmptyErrorMessage;
              }
              try {
                var intId = int.parse(value);
                if (intId < 0) {
                  throw Exception;
                }
              } catch (e) {
                return notIntegerErrorMessage;
              }
              return null;
            },
          ),

          // User height
          TextFormField(
            controller: widget.heightController,
            decoration: const InputDecoration(labelText: userHeightLabel),
            keyboardType: TextInputType.number,

            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return valueEmptyErrorMessage;
              }
              try {
                var intId = int.parse(value);
                if (intId < 0) {
                  throw Exception;
                }
              } catch (e) {
                return notIntegerErrorMessage;
              }
              return null;
            },
          ),

          // User weight
          TextFormField(
            controller: widget.weightController,
            decoration: const InputDecoration(labelText: userWeightLabel),
            keyboardType: TextInputType.number,

            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return valueEmptyErrorMessage;
              }
              try {
                var intId = int.parse(value);
                if (intId < 0) {
                  throw Exception;
                }
              } catch (e) {
                return notIntegerErrorMessage;
              }
              return null;
            },
          ),

          // User birth sex
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            child: DropdownButtonFormField(
              alignment: Alignment.center,
              isDense: true,
              value: sexDropdownValue,
              decoration: const InputDecoration(labelText: userSexLabel),
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              onChanged: (String? value) {
                // This is called when the user selects an item.
                sexDropdownValue = value!;
                widget.sexController.text = value!;
              },
              validator: (value) {
                if (widget.sexController.text == "") {
                  return valueEmptyErrorMessage;
                }
              },
              items: sexList.map<DropdownMenuItem<String>>((var value) {
                return DropdownMenuItem(
                  value: value.toString(),
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),

        ],
      ),
    );
  }

}