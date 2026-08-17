import 'package:flutter/material.dart';

import 'status/status_list_page.dart';
import 'template/template_list_page.dart';

const saffron = Color(0xFFFF6B00);
const amber = Color(0xFFD4A017);
const deepOr = Color(0xFFB5451B);
const cream = Color(0xFFFFF8F0);
const brown = Color(0xFF2C1810);

class ContentManagementPage
    extends StatelessWidget {
  const ContentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: const Text(
          'Content Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount:
          MediaQuery.of(context).size.width > 700
              ? 2
              : 1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 2.2,
          children: [
            _contentCard(
              context,
              icon: Icons.auto_awesome,
              title: 'Status',
              subtitle:
              'Status add, edit, delete & categories',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const StatusListPage(),
                  ),
                );
              },
            ),
            _contentCard(
              context,
              icon: Icons.design_services_rounded,
              title: 'Templates',
              subtitle:
              'Template add, edit, delete & categories',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const TemplateListPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: saffron.withOpacity(.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: saffron.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: deepOr,
                size: 32,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w900,
                      color: brown,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.brown.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: saffron,
            ),
          ],
        ),
      ),
    );
  }
}