import 'package:finlytics/app/accounts/account_selector.dart';
import 'package:finlytics/app/categories/categories_list.dart';
import 'package:finlytics/core/database/services/account/account_service.dart';
import 'package:finlytics/core/database/services/budget/budget_service.dart';
import 'package:finlytics/core/database/services/category/category_service.dart';
import 'package:finlytics/core/models/budget/budget.dart';
import 'package:finlytics/core/models/category/category.dart';
import 'package:finlytics/core/models/transaction/transaction.dart';
import 'package:finlytics/core/presentation/widgets/currency_displayer.dart';
import 'package:finlytics/core/utils/text_field_validator.dart';
import 'package:finlytics/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/account/account.dart';
import '../../core/presentation/widgets/persistent_footer_button.dart';

class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({super.key, this.budgetToEdit, required this.prevPage});

  final Budget? budgetToEdit;

  final Widget prevPage;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.budgetToEdit != null;

  TextEditingController valueController = TextEditingController();
  double? get valueToNumber => double.tryParse(valueController.text);

  TextEditingController nameController = TextEditingController();

  List<Category> categories = [];
  List<Account> accounts = [];

  TransactionPeriodicity? intervalPeriod = TransactionPeriodicity.month;

  Widget selector({
    required String title,
    required String? inputValue,
    required Function onClick,
  }) {
    return TextFormField(
        controller: TextEditingController(text: inputValue ?? ''),
        readOnly: true,
        onTap: () => onClick(),
        validator: (value) {
          if (inputValue == null) {
            return 'Please, specify at least one item here';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: title,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ));
  }

  submitForm() {
    final t = Translations.of(context);

    if (valueToNumber! < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.budgets.form.negative_warn)));

      return;
    }

    onSuccess() {
      Navigator.pop(context);
      Navigator.pop(context);

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => widget.prevPage));

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEditMode
              ? t.transaction.edit_success
              : t.transaction.new_success)));
    }

    final Budget toPush;

    toPush = Budget(
      id: isEditMode ? widget.budgetToEdit!.id : const Uuid().v4(),
      name: nameController.text,
      limitAmount: valueToNumber!,
      intervalPeriod: intervalPeriod,
      categories: categories.map((e) => e.id).toList(),
      accounts: accounts.map((e) => e.id).toList(),
    );

    if (isEditMode) {
      BudgetServive.instance.updateBudget(toPush).then((value) {
        onSuccess();
      }).catchError((error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      });
    } else {
      BudgetServive.instance.insertBudget(toPush).then((value) {
        onSuccess();
      }).catchError((error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      fillForm(widget.budgetToEdit!);
    }
  }

  fillForm(Budget budget) {
    nameController.text = budget.name;
    valueController.text = budget.limitAmount.abs().toString();

    CategoryService.instance
        .getCategories(
          predicate: (p0, p1) => p0.id.isIn(budget.categories),
        )
        .first
        .then((value) {
      setState(() {
        categories = value;
      });
    });

    AccountService.instance
        .getAccounts(
          predicate: (p0, p1) => p0.id.isIn(budget.accounts),
        )
        .first
        .then((value) {
      setState(() {
        accounts = value;
      });
    });

    setState(() {
      intervalPeriod = budget.intervalPeriod;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? t.budgets.form.edit : t.budgets.form.create),
        ),
        persistentFooterButtons: [
          PersistentFooterButton(
            child: FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  submitForm();
                }
              },
              icon: const Icon(Icons.save),
              label: Text(
                  isEditMode ? t.budgets.form.edit : t.budgets.form.create),
            ),
          )
        ],
        body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameController,
                  maxLength: 15,
                  validator: (value) => fieldValidator(value, isRequired: true),
                  decoration: InputDecoration(
                    labelText: '${t.budgets.form.name} *',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  decoration: InputDecoration(
                      labelText: 'Amount *',
                      hintText: 'Ex.: 200',
                      suffix: valueToNumber != null
                          ? Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: CurrencyDisplayer(
                                  amountToConvert: valueToNumber!),
                            )
                          : null),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final defaultNumberValidatorResult = fieldValidator(value,
                        isRequired: true, validator: ValidatorType.double);

                    if (defaultNumberValidatorResult != null) {
                      return defaultNumberValidatorResult;
                    }

                    if (valueToNumber! == 0) {
                      return t.transaction.form.validators.zero;
                    }

                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                selector(
                    title: '${t.general.accounts} *',
                    inputValue: accounts.isNotEmpty
                        ? accounts.map((e) => e.name).join(', ')
                        : null,
                    onClick: () async {
                      final modalRes =
                          await showModalBottomSheet<List<Account>>(
                        context: context,
                        builder: (context) {
                          return AccountSelector(
                            allowMultiSelection: true,
                            filterSavingAccounts: false,
                            selectedAccounts: accounts,
                          );
                        },
                      );

                      if (modalRes != null) {
                        setState(() {
                          accounts = modalRes;
                        });
                      }
                    }),
                const SizedBox(height: 16),
                selector(
                    title: '${t.general.categories} *',
                    inputValue: categories.isNotEmpty
                        ? categories.map((e) => e.name).join(', ')
                        : null,
                    onClick: () async {
                      final modalRes =
                          await showModalBottomSheet<List<Category>>(
                        context: context,
                        builder: (context) {
                          return CategoriesList(
                            mode: CategoriesListMode.modalSelectMultiCategory,
                            selectedCategories: categories,
                          );
                        },
                      );

                      if (modalRes != null) {
                        setState(() {
                          categories = modalRes;
                        });
                      }
                    }),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  value: intervalPeriod,
                  decoration: InputDecoration(
                    labelText: '${t.budgets.form.repetition} *',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Ninguno'),
                    ),
                    ...List.generate(
                        TransactionPeriodicity.values.length,
                        (index) => DropdownMenuItem(
                            value: TransactionPeriodicity.values[index],
                            child: Text(
                                TransactionPeriodicity.values[index].name)))
                  ],
                  onChanged: (value) {
                    setState(() {
                      intervalPeriod = value;
                    });
                  },
                ),
              ]),
            )));
  }
}