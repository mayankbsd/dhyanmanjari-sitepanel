import 'package:flutter/material.dart';

import 'template_form_page.dart';

const saffron = Color(0xFFFF6B00);
const deepOr = Color(0xFFB5451B);
const cream = Color(0xFFFFF8F0);
const brown = Color(0xFF2C1810);

class TemplateListPage
    extends StatefulWidget {
  const TemplateListPage({super.key});

  @override
  State<TemplateListPage> createState() =>
      _TemplateListPageState();
}

class _TemplateListPageState
    extends State<TemplateListPage> {

  final List<Map<String, dynamic>>
  templates = [];

  String selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: const Text(
          'Template Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const TemplateFormPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Template',
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding:
            const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Category:',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                    color: brown,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child:
                      Text('All Categories'),
                    ),
                    DropdownMenuItem(
                      value: 'mantra',
                      child:
                      Text('मंत्र'),
                    ),
                    DropdownMenuItem(
                      value: 'greetings',
                      child:
                      Text('शुभकामनाएं'),
                    ),
                    DropdownMenuItem(
                      value: 'devotion',
                      child:
                      Text('भक्ति'),
                    ),
                    DropdownMenuItem(
                      value: 'festivals',
                      child:
                      Text('त्योहार'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(
                          () => selectedCategory =
                          value,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: templates.isEmpty
                ? const Center(
              child: Text(
                'कोई Template उपलब्ध नहीं है',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w700,
                  color: brown,
                ),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.all(
                20,
              ),
              itemCount:
              templates.length,
              itemBuilder:
                  (_, index) {
                return _templateCard(
                  templates[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(
      Map<String, dynamic> item) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color:
              saffron.withOpacity(.1),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.image,
              color: deepOr,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Template Title',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                    color: brown,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'मंत्र',
                  style: TextStyle(
                    color: deepOr,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const TemplateFormPage(
                    isEdit: true,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
              color: deepOr,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}