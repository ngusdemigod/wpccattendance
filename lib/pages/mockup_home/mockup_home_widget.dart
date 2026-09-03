import 'package:flutter/material.dart';

class MockupHomeWidget extends StatefulWidget {
  const MockupHomeWidget({super.key});

  @override
  State<MockupHomeWidget> createState() => _MockupHomeWidgetState();
}

class _MockupHomeWidgetState extends State<MockupHomeWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
                  height: 800.0,
                  margin: const EdgeInsets.all(0.0),
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFF4F4), Color(0xFFD5E0E5), Color(0xFFC8D3D8)])),
                  child: Container(
                      width: 1500.0,
                      height: 1880.0,
                      padding: const EdgeInsets.fromLTRB(44.0, 40.0, 44.0, 54.0),
                      margin: const EdgeInsets.all(0.0),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 28.0),
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(0.0),
                                  child: const Text(
                                  "Manifest Home Page Mockups",
                                  style: TextStyle(fontSize: 42.0, fontWeight: FontWeight.w400, letterSpacing: -1.2, height: 1.0, fontFamily: "Instrument Serif"),
                                ),
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 700.0),
                                    child: Container(
                                  margin: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                                  child: const Text(
                                  "Light and dark mode home states using the Manifest design system, Instrument Sans, Instrument Serif, and the supplied attendance streak reference. All screen layouts are preserved.",
                                  style: TextStyle(fontSize: 16.0, height: 1.55, fontFamily: "Instrument Sans"),
                                ),
                                ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 12.0),
                              decoration: BoxDecoration(color: const Color(0xA3FFFFFF), border: Border.all(color: const Color(0xC7FFFFFF), width: 1.0)),
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 22.0),
                                  child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(child: Text(
                                      "Light 01 / Home Overview",
                                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                    )),
                                    Flexible(child: Text(
                                          "Global + departmental announcements",
                                          style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                        )),
                                  ],
                                ),
                                ),
                                const SizedBox(height: 14.0),
                                Container(
                                  width: 3.0,
                                  height: 100.0,
                                  padding: const EdgeInsets.all(9.0),
                                  decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C0C0D), Color(0xFF2B2C2F)]), borderRadius: BorderRadius.circular(0.0), boxShadow: const [BoxShadow(color: Color(0x47101820), offset: Offset(0.0, 28.0), blurRadius: 58.0, spreadRadius: 0.0)]),
                                  child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(39.0)),
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 112.0,
                                          height: 26.0,
                                          decoration: BoxDecoration(color: const Color(0xFF08080A), borderRadius: BorderRadius.circular(999.0)),
                                          child: const SizedBox.shrink(),
                                        ),
                                        Container(
                                          height: 43.0,
                                          padding: const EdgeInsets.fromLTRB(21.0, 13.0, 21.0, 0.0),
                                          child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Flexible(child: Text(
                                                  "9:41",
                                                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                )),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 10.0),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 14.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Good evening,",
                                                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w400, letterSpacing: -0.2, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 0.0),
                                                      child: const Text(
                                                      "Adeshina",
                                                      style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w400, letterSpacing: -0.8, height: 1.0, fontFamily: "Instrument Serif"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Container(
                                                      width: 7.0,
                                                      height: 7.0,
                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFFFFFF), width: 2.0)),
                                                      child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Container(
                                                          width: 19.0,
                                                          height: 19.0,
                                                          color: const Color(0xFFEEEEEE),
                                                          alignment: Alignment.center,
                                                          child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                    const SizedBox(width: 9.0),
                                                    Flexible(child: Container(
                                                      width: 36.0,
                                                      height: 36.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFD496), Color(0xFF8B4C31)]), boxShadow: [BoxShadow(color: Color(0xA6FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 2.0)]),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "AG",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                              margin: EdgeInsets.zero,
                                              child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Today",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Global",
                                                      style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Departments",
                                                      style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Events",
                                                      style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Goals",
                                                      style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              height: 170.0,
                                              padding: const EdgeInsets.all(18.0),
                                              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [Color(0x00000000), Color(0xC2FFFFFF), Color(0x00000000)])),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                                                  child: const Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Flexible(child: Text(
                                                          "WISDOM POWER",
                                                          style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.1, height: 1.05, fontFamily: "Instrument Sans"),
                                                        )),
                                                        SizedBox(height: 16.0),
                                                        Flexible(child: Text(
                                                          "CHRISTIAN CENTRE",
                                                          style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.1, height: 1.05, fontFamily: "Instrument Sans"),
                                                        )),
                                                      ],
                                                    )),
                                                  ],
                                                ),
                                                ),
                                                Align(
                                                  alignment: Alignment.topCenter,
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 230.0),
                                                    child: Container(
                                                  child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "I MANIFEST MAJOR",
                                                      style: TextStyle(color: Color(0xFF6E321F), fontSize: 25.0, fontWeight: FontWeight.w800, letterSpacing: -1.15, height: 0.88, fontFamily: "Instrument Serif"),
                                                    ),
                                                    Text(
                                                      "BREAKTHROUGH",
                                                      style: TextStyle(color: Color(0xFF171312), fontSize: 30.0, fontWeight: FontWeight.w800, letterSpacing: -1.15, height: 0.88, fontFamily: "Instrument Serif"),
                                                    ),
                                                    Text(
                                                      "IN GLORY",
                                                      style: TextStyle(color: Color(0xFF6E321F), fontSize: 25.0, fontWeight: FontWeight.w800, letterSpacing: -1.15, height: 0.88, fontFamily: "Instrument Serif"),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 9.0),
                                                  margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFD71920), borderRadius: BorderRadius.circular(3.0)),
                                                  child: const Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "JUNE 2026",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 10.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.max,
                                                  children: [
                                                    const Flexible(child: Text(
                                                          "Family Worship Service • 8:00pm",
                                                          style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                        )),
                                                    ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0)),
                                                      child: const Text("View", style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Departmental Announcements",
                                                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "View all ›",
                                                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(11.0),
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 40.0,
                                                      height: 40.0,
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "♪",
                                                          style: TextStyle(fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Choir rehearsal moved",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Music team meets at 6:30pm in Hall B.",
                                                          style: TextStyle(fontSize: 10.5, height: 1.3, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 7.0),
                                                      color: const Color(0x1F1F8A4C),
                                                      child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Flexible(child: Text(
                                                          "New",
                                                          style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        )),
                                                      ],
                                                    ),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 9.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(11.0),
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 40.0,
                                                      height: 40.0,
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "↗",
                                                          style: TextStyle(fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Ushering team briefing",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Pre-service huddle starts 20 minutes early.",
                                                          style: TextStyle(fontSize: 10.5, height: 1.3, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 7.0),
                                                      color: const Color(0x1F1F8A4C),
                                                      child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Flexible(child: Text(
                                                          "Dept",
                                                          style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        )),
                                                      ],
                                                    ),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Trending Events",
                                                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "View more ›",
                                                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                              margin: EdgeInsets.zero,
                                              child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(child: SizedBox(
                                                  width: 145.0,
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 96.0,
                                                      padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 10.0),
                                                      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF8D7), Color(0xFFF2C66C)]), borderRadius: BorderRadius.circular(20.0)),
                                                      child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                          child: const Text(
                                                              "WPC MEGA CHURCH",
                                                              style: TextStyle(fontSize: 7.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                            ),
                                                        ),
                                                        const Text(
                                                              "GLORY NIGHT",
                                                              style: TextStyle(color: Color(0xFF713B25), fontSize: 16.0, fontWeight: FontWeight.w800, height: 0.92, fontFamily: "Instrument Serif"),
                                                            ),
                                                      ],
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "Glory Night",
                                                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Sat 30th Aug, 8:00pm",
                                                      style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 11.0),
                                                Flexible(child: SizedBox(
                                                  width: 145.0,
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 96.0,
                                                      padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 10.0),
                                                      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFBE6F6), Color(0xFFF5D6A5)]), borderRadius: BorderRadius.circular(20.0)),
                                                      child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                          child: const Text(
                                                              "YOUTH FELLOWSHIP",
                                                              style: TextStyle(fontSize: 7.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                            ),
                                                        ),
                                                        const Text(
                                                              "PRAISE PARTY",
                                                              style: TextStyle(color: Color(0xFF713B25), fontSize: 16.0, fontWeight: FontWeight.w800, height: 0.92, fontFamily: "Instrument Serif"),
                                                            ),
                                                      ],
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "Youth Praise Party",
                                                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Sun 31st Aug, 5:00pm",
                                                      style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                              ],
                                            ),
                                            ),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          height: 74.0,
                                          padding: const EdgeInsets.fromLTRB(22.0, 8.0, 22.0, 19.0),
                                          color: const Color(0xF0FFFFFF),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Home",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Events",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "People",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Profile",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                            ],
                                          ),
                                          ],
                                        ),
                                        ),
                                      ],
                                    ),
                                    ),
                                ),
                              ],
                            )),
                              const SizedBox(width: 38.0),
                              Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 22.0),
                                  child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(child: Text(
                                      "Light 02 / Social + Streaks",
                                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                    )),
                                    Flexible(child: Text(
                                          "People suggestions + activity streaks",
                                          style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                        )),
                                  ],
                                ),
                                ),
                                const SizedBox(height: 14.0),
                                Container(
                                  width: 3.0,
                                  height: 100.0,
                                  padding: const EdgeInsets.all(9.0),
                                  decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C0C0D), Color(0xFF2B2C2F)]), borderRadius: BorderRadius.circular(0.0), boxShadow: const [BoxShadow(color: Color(0x47101820), offset: Offset(0.0, 28.0), blurRadius: 58.0, spreadRadius: 0.0)]),
                                  child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(39.0)),
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 112.0,
                                          height: 26.0,
                                          decoration: BoxDecoration(color: const Color(0xFF08080A), borderRadius: BorderRadius.circular(999.0)),
                                          child: const SizedBox.shrink(),
                                        ),
                                        Container(
                                          height: 43.0,
                                          padding: const EdgeInsets.fromLTRB(21.0, 13.0, 21.0, 0.0),
                                          child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Flexible(child: Text(
                                                  "9:41",
                                                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                )),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 10.0),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Home",
                                                      style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w400, letterSpacing: -0.8, fontFamily: "Instrument Serif"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0),
                                                      child: const Text(
                                                      "Build community and keep your rhythm.",
                                                      style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  width: 36.0,
                                                  height: 36.0,
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 19.0,
                                                      height: 19.0,
                                                      color: const Color(0xFFEEEEEE),
                                                      alignment: Alignment.center,
                                                      child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "People Suggestions",
                                                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "See all ›",
                                                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 42.0,
                                                      height: 42.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B4C31), Color(0xFFD88100)])),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "TM",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Tomiwa Martins",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "New in your department • 4 mutuals",
                                                          style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0)),
                                                      child: const Text("Connect", style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 42.0,
                                                      height: 42.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B4C31), Color(0xFFD88100)])),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "OA",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Oyin Adebayo",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Attended 3 services with you",
                                                          style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0)),
                                                      child: const Text("Follow", style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 42.0,
                                                      height: 42.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B4C31), Color(0xFFD88100)])),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "CN",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Chidi Nwosu",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Serving team recommendation",
                                                          style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0)),
                                                      child: const Text("Follow", style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Goals",
                                                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "Manage ›",
                                                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(14.0),
                                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                      child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.max,
                                                      children: [
                                                        Flexible(child: Text(
                                                              "Attend 4 services",
                                                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                        Flexible(child: Text(
                                                              "3/4",
                                                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                      ],
                                                    ),
                                                    ),
                                                    const SizedBox(
                                                      height: 8.0,
                                                      child: SizedBox.shrink(),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                      child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.max,
                                                      children: [
                                                        Flexible(child: Text(
                                                              "Invite 2 new people",
                                                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                        Flexible(child: Text(
                                                              "1/2",
                                                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                      ],
                                                    ),
                                                    ),
                                                    const SizedBox(
                                                      height: 8.0,
                                                      child: SizedBox.shrink(),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                      child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.max,
                                                      children: [
                                                        Flexible(child: Text(
                                                              "Complete devotionals",
                                                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                        Flexible(child: Text(
                                                              "5/7",
                                                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                      ],
                                                    ),
                                                    ),
                                                    const SizedBox(
                                                      height: 8.0,
                                                      child: SizedBox.shrink(),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                              ],
                                            ),
                                            ),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          height: 74.0,
                                          padding: const EdgeInsets.fromLTRB(22.0, 8.0, 22.0, 19.0),
                                          color: const Color(0xF0FFFFFF),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Home",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Events",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "People",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Profile",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                            ],
                                          ),
                                          ],
                                        ),
                                        ),
                                      ],
                                    ),
                                    ),
                                ),
                              ],
                            )),
                              const SizedBox(width: 38.0),
                              Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 22.0),
                                  child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(child: Text(
                                      "Light 03 / Goals + Strategies",
                                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                    )),
                                    Flexible(child: Text(
                                          "Growth plan + primary action",
                                          style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                        )),
                                  ],
                                ),
                                ),
                                const SizedBox(height: 14.0),
                                Container(
                                  width: 3.0,
                                  height: 100.0,
                                  padding: const EdgeInsets.all(9.0),
                                  decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C0C0D), Color(0xFF2B2C2F)]), borderRadius: BorderRadius.circular(0.0), boxShadow: const [BoxShadow(color: Color(0x47101820), offset: Offset(0.0, 28.0), blurRadius: 58.0, spreadRadius: 0.0)]),
                                  child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(39.0)),
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 112.0,
                                          height: 26.0,
                                          decoration: BoxDecoration(color: const Color(0xFF08080A), borderRadius: BorderRadius.circular(999.0)),
                                          child: const SizedBox.shrink(),
                                        ),
                                        Container(
                                          height: 43.0,
                                          padding: const EdgeInsets.fromLTRB(21.0, 13.0, 21.0, 0.0),
                                          child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Flexible(child: Text(
                                                  "9:41",
                                                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                )),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 10.0),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Strategies",
                                                      style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w400, letterSpacing: -0.8, fontFamily: "Instrument Serif"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0),
                                                      child: const Text(
                                                      "Your focus plan for this week.",
                                                      style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  width: 36.0,
                                                  height: 36.0,
                                                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFD496), Color(0xFF8B4C31)]), boxShadow: [BoxShadow(color: Color(0xA6FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 2.0)]),
                                                  child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Text(
                                                      "AG",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                              margin: EdgeInsets.zero,
                                              child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "24",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Mon",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "25",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Tue",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "26",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Wed",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "27",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Thu",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "28",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Fri",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: 110.0,
                                              height: 110.0,
                                              padding: const EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(color: const Color(0x1FC5099C), border: Border.all(color: const Color(0xFFF3DAE9), width: 1.0)),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                                                  color: const Color(0xFFFFFFFF),
                                                  child: const Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "TODAY’S STRATEGY",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                ),
                                                Align(
                                                  alignment: Alignment.topCenter,
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 220.0),
                                                    child: Container(
                                                  margin: const EdgeInsets.fromLTRB(0.0, 11.0, 0.0, 6.0),
                                                  child: const Text(
                                                  "Invite one family before service.",
                                                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, height: 1.12, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment: Alignment.topCenter,
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 240.0),
                                                    child: Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Share the Family Worship Service with someone nearby and offer to meet them at the entrance.",
                                                  style: TextStyle(fontSize: 11.0, height: 1.45, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Action Plan",
                                                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "Edit goals ›",
                                                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(12.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 38.0,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "✦",
                                                          style: TextStyle(fontSize: 17.0, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Pray for two invitees",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Set a 10-minute checkpoint today.",
                                                          style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      width: 23.0,
                                                      height: 23.0,
                                                      decoration: BoxDecoration(color: const Color(0x1F1F8A4C), border: Border.all(color: const Color(0xFF000000), width: 1.5)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "✓",
                                                          style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(12.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 38.0,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "⌁",
                                                          style: TextStyle(fontSize: 17.0, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Join department huddle",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Connect with your serving team.",
                                                          style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      width: 23.0,
                                                      height: 23.0,
                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF000000), width: 1.5)),
                                                      child: const SizedBox.shrink(),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(12.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 38.0,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "↗",
                                                          style: TextStyle(fontSize: 17.0, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Share testimony after service",
                                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Post in community or send to host.",
                                                          style: TextStyle(fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      width: 23.0,
                                                      height: 23.0,
                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF000000), width: 1.5)),
                                                      child: const SizedBox.shrink(),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Upcoming Service",
                                                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "Open ›",
                                                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(11.0),
                                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF000000), width: 1.0)),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 40.0,
                                                  height: 40.0,
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                  child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Text(
                                                      "⌚",
                                                      style: TextStyle(fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                  const SizedBox(width: 10.0),
                                                  Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                      child: const Text(
                                                      "Family Worship Service",
                                                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Tonight • 8:00pm – 02:00am • His Glory Expression",
                                                      style: TextStyle(fontSize: 10.5, height: 1.3, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                )),
                                                  const SizedBox(width: 10.0),
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 7.0),
                                                  color: const Color(0x1F1F8A4C),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Live",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            ),
                                          ],
                                        ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF)),
                                          child: const Text("Check in to service", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans")),
                                        ),
                                        Container(
                                          height: 74.0,
                                          padding: const EdgeInsets.fromLTRB(22.0, 8.0, 22.0, 19.0),
                                          color: const Color(0xF0FFFFFF),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Home",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Events",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "People",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Profile",
                                                      style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                            ],
                                          ),
                                          ],
                                        ),
                                        ),
                                      ],
                                    ),
                                    ),
                                ),
                              ],
                            )),
                            ],
                          ),
                            const SizedBox(height: 54.0),
                            Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 22.0),
                                  child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(child: Text(
                                      "Dark 01 / Home Overview",
                                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                    )),
                                    Flexible(child: Text(
                                          "Global + departmental announcements",
                                          style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                        )),
                                  ],
                                ),
                                ),
                                const SizedBox(height: 14.0),
                                Container(
                                  width: 3.0,
                                  height: 100.0,
                                  padding: const EdgeInsets.all(9.0),
                                  decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C0C0D), Color(0xFF2B2C2F)]), borderRadius: BorderRadius.circular(0.0), boxShadow: const [BoxShadow(color: Color(0x47101820), offset: Offset(0.0, 28.0), blurRadius: 58.0, spreadRadius: 0.0)]),
                                  child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: const Color(0xFF101113), borderRadius: BorderRadius.circular(39.0)),
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 112.0,
                                          height: 26.0,
                                          decoration: BoxDecoration(color: const Color(0xFF08080A), borderRadius: BorderRadius.circular(999.0)),
                                          child: const SizedBox.shrink(),
                                        ),
                                        Container(
                                          height: 43.0,
                                          padding: const EdgeInsets.fromLTRB(21.0, 13.0, 21.0, 0.0),
                                          child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Flexible(child: Text(
                                                  "9:41",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                )),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 10.0),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 14.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Good evening,",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 18.0, fontWeight: FontWeight.w400, letterSpacing: -0.2, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 0.0),
                                                      child: const Text(
                                                      "Adeshina",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 30.0, fontWeight: FontWeight.w400, letterSpacing: -0.8, height: 1.0, fontFamily: "Instrument Serif"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Container(
                                                      width: 7.0,
                                                      height: 7.0,
                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 2.0)),
                                                      child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Container(
                                                          width: 19.0,
                                                          height: 19.0,
                                                          color: const Color(0xFFEEEEEE),
                                                          alignment: Alignment.center,
                                                          child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                    const SizedBox(width: 9.0),
                                                    Flexible(child: Container(
                                                      width: 36.0,
                                                      height: 36.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFD496), Color(0xFF8B4C31)]), boxShadow: [BoxShadow(color: Color(0xA6FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 2.0)]),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "AG",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                              margin: EdgeInsets.zero,
                                              child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  color: const Color(0xFFFFFFFF),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Today",
                                                      style: TextStyle(color: Color(0xFFE6E5E4), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  color: const Color(0x33C5099C),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Global",
                                                      style: TextStyle(color: Color(0xFFFF7AD8), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Departments",
                                                      style: TextStyle(color: Color(0xFFE6E5E4), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Events",
                                                      style: TextStyle(color: Color(0xFFE6E5E4), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 7.0),
                                                Flexible(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 11.0),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Goals",
                                                      style: TextStyle(color: Color(0xFFE6E5E4), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              height: 170.0,
                                              padding: const EdgeInsets.all(18.0),
                                              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [Color(0x00000000), Color(0xC2FFFFFF), Color(0x00000000)])),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                                                  child: const Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Flexible(child: Text(
                                                          "WISDOM POWER",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.1, height: 1.05, fontFamily: "Instrument Sans"),
                                                        )),
                                                        SizedBox(height: 16.0),
                                                        Flexible(child: Text(
                                                          "CHRISTIAN CENTRE",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.1, height: 1.05, fontFamily: "Instrument Sans"),
                                                        )),
                                                      ],
                                                    )),
                                                  ],
                                                ),
                                                ),
                                                Align(
                                                  alignment: Alignment.topCenter,
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 230.0),
                                                    child: Container(
                                                  child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "I MANIFEST MAJOR",
                                                      style: TextStyle(color: Color(0xFF6E321F), fontSize: 25.0, fontWeight: FontWeight.w800, letterSpacing: -1.15, height: 0.88, fontFamily: "Instrument Serif"),
                                                    ),
                                                    Text(
                                                      "BREAKTHROUGH",
                                                      style: TextStyle(color: Color(0xFF171312), fontSize: 30.0, fontWeight: FontWeight.w800, letterSpacing: -1.15, height: 0.88, fontFamily: "Instrument Serif"),
                                                    ),
                                                    Text(
                                                      "IN GLORY",
                                                      style: TextStyle(color: Color(0xFF6E321F), fontSize: 25.0, fontWeight: FontWeight.w800, letterSpacing: -1.15, height: 0.88, fontFamily: "Instrument Serif"),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 9.0),
                                                  margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFD71920), borderRadius: BorderRadius.circular(3.0)),
                                                  child: const Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "JUNE 2026",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 10.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.max,
                                                  children: [
                                                    const Flexible(child: Text(
                                                          "Family Worship Service • 8:00pm",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                        )),
                                                    ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0)),
                                                      child: const Text("View", style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Departmental Announcements",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "View all ›",
                                                    style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(11.0),
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 40.0,
                                                      height: 40.0,
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "♪",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Choir rehearsal moved",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Music team meets at 6:30pm in Hall B.",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.5, height: 1.3, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 7.0),
                                                      color: const Color(0x1F1F8A4C),
                                                      child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Flexible(child: Text(
                                                          "New",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 9.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        )),
                                                      ],
                                                    ),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 9.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(11.0),
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 40.0,
                                                      height: 40.0,
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "↗",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Ushering team briefing",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Pre-service huddle starts 20 minutes early.",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.5, height: 1.3, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 7.0),
                                                      color: const Color(0x1F1F8A4C),
                                                      child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Flexible(child: Text(
                                                          "Dept",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 9.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        )),
                                                      ],
                                                    ),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Trending Events",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "View more ›",
                                                    style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                              margin: EdgeInsets.zero,
                                              child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(child: SizedBox(
                                                  width: 145.0,
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 96.0,
                                                      padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 10.0),
                                                      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF8D7), Color(0xFFF2C66C)]), borderRadius: BorderRadius.circular(20.0)),
                                                      child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                          child: const Text(
                                                              "WPC MEGA CHURCH",
                                                              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 7.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                            ),
                                                        ),
                                                        const Text(
                                                              "GLORY NIGHT",
                                                              style: TextStyle(color: Color(0xFF713B25), fontSize: 16.0, fontWeight: FontWeight.w800, height: 0.92, fontFamily: "Instrument Serif"),
                                                            ),
                                                      ],
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "Glory Night",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Sat 30th Aug, 8:00pm",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 11.0),
                                                Flexible(child: SizedBox(
                                                  width: 145.0,
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 96.0,
                                                      padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 10.0),
                                                      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFBE6F6), Color(0xFFF5D6A5)]), borderRadius: BorderRadius.circular(20.0)),
                                                      child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                          child: const Text(
                                                              "YOUTH FELLOWSHIP",
                                                              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 7.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                            ),
                                                        ),
                                                        const Text(
                                                              "PRAISE PARTY",
                                                              style: TextStyle(color: Color(0xFF713B25), fontSize: 16.0, fontWeight: FontWeight.w800, height: 0.92, fontFamily: "Instrument Serif"),
                                                            ),
                                                      ],
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "Youth Praise Party",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Sun 31st Aug, 5:00pm",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                              ],
                                            ),
                                            ),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          height: 74.0,
                                          padding: const EdgeInsets.fromLTRB(22.0, 8.0, 22.0, 19.0),
                                          color: const Color(0xF00F1112),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Home",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Events",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "People",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Profile",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                            ],
                                          ),
                                          ],
                                        ),
                                        ),
                                      ],
                                    ),
                                    ),
                                ),
                              ],
                            )),
                              const SizedBox(width: 38.0),
                              Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 22.0),
                                  child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(child: Text(
                                      "Dark 02 / Social + Streaks",
                                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                    )),
                                    Flexible(child: Text(
                                          "People suggestions + activity streaks",
                                          style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                        )),
                                  ],
                                ),
                                ),
                                const SizedBox(height: 14.0),
                                Container(
                                  width: 3.0,
                                  height: 100.0,
                                  padding: const EdgeInsets.all(9.0),
                                  decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C0C0D), Color(0xFF2B2C2F)]), borderRadius: BorderRadius.circular(0.0), boxShadow: const [BoxShadow(color: Color(0x47101820), offset: Offset(0.0, 28.0), blurRadius: 58.0, spreadRadius: 0.0)]),
                                  child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: const Color(0xFF101113), borderRadius: BorderRadius.circular(39.0)),
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 112.0,
                                          height: 26.0,
                                          decoration: BoxDecoration(color: const Color(0xFF08080A), borderRadius: BorderRadius.circular(999.0)),
                                          child: const SizedBox.shrink(),
                                        ),
                                        Container(
                                          height: 43.0,
                                          padding: const EdgeInsets.fromLTRB(21.0, 13.0, 21.0, 0.0),
                                          child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Flexible(child: Text(
                                                  "9:41",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                )),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 10.0),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Home",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 28.0, fontWeight: FontWeight.w400, letterSpacing: -0.8, fontFamily: "Instrument Serif"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0),
                                                      child: const Text(
                                                      "Build community and keep your rhythm.",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 12.0, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  width: 36.0,
                                                  height: 36.0,
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 19.0,
                                                      height: 19.0,
                                                      color: const Color(0xFFEEEEEE),
                                                      alignment: Alignment.center,
                                                      child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "People Suggestions",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "See all ›",
                                                    style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 42.0,
                                                      height: 42.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B4C31), Color(0xFFD88100)])),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "TM",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Tomiwa Martins",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "New in your department • 4 mutuals",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFFFFF), foregroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0)),
                                                      child: const Text("Connect", style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 42.0,
                                                      height: 42.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B4C31), Color(0xFFD88100)])),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "OA",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Oyin Adebayo",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Attended 3 services with you",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0x33C5099C), foregroundColor: const Color(0xFFFF7AD8), padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0)),
                                                      child: const Text("Follow", style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 42.0,
                                                      height: 42.0,
                                                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B4C31), Color(0xFFD88100)])),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "CN",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Chidi Nwosu",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Serving team recommendation",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0x33C5099C), foregroundColor: const Color(0xFFFF7AD8), padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0)),
                                                      child: const Text("Follow", style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans")),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Goals",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "Manage ›",
                                                    style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(14.0),
                                              decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                      child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.max,
                                                      children: [
                                                        Flexible(child: Text(
                                                              "Attend 4 services",
                                                              style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                        Flexible(child: Text(
                                                              "3/4",
                                                              style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                      ],
                                                    ),
                                                    ),
                                                    const SizedBox(
                                                      height: 8.0,
                                                      child: SizedBox.shrink(),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                      child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.max,
                                                      children: [
                                                        Flexible(child: Text(
                                                              "Invite 2 new people",
                                                              style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                        Flexible(child: Text(
                                                              "1/2",
                                                              style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                      ],
                                                    ),
                                                    ),
                                                    const SizedBox(
                                                      height: 8.0,
                                                      child: SizedBox.shrink(),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 7.0),
                                                      child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.max,
                                                      children: [
                                                        Flexible(child: Text(
                                                              "Complete devotionals",
                                                              style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                        Flexible(child: Text(
                                                              "5/7",
                                                              style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                            )),
                                                      ],
                                                    ),
                                                    ),
                                                    const SizedBox(
                                                      height: 8.0,
                                                      child: SizedBox.shrink(),
                                                    ),
                                                  ],
                                                ),
                                                ),
                                              ],
                                            ),
                                            ),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          height: 74.0,
                                          padding: const EdgeInsets.fromLTRB(22.0, 8.0, 22.0, 19.0),
                                          color: const Color(0xF00F1112),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Home",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Events",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "People",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Profile",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                            ],
                                          ),
                                          ],
                                        ),
                                        ),
                                      ],
                                    ),
                                    ),
                                ),
                              ],
                            )),
                              const SizedBox(width: 38.0),
                              Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 22.0),
                                  child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(child: Text(
                                      "Dark 03 / Goals + Strategies",
                                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                    )),
                                    Flexible(child: Text(
                                          "Growth plan + primary action",
                                          style: TextStyle(fontSize: 12.0, fontFamily: "Instrument Sans"),
                                        )),
                                  ],
                                ),
                                ),
                                const SizedBox(height: 14.0),
                                Container(
                                  width: 3.0,
                                  height: 100.0,
                                  padding: const EdgeInsets.all(9.0),
                                  decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C0C0D), Color(0xFF2B2C2F)]), borderRadius: BorderRadius.circular(0.0), boxShadow: const [BoxShadow(color: Color(0x47101820), offset: Offset(0.0, 28.0), blurRadius: 58.0, spreadRadius: 0.0)]),
                                  child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: const Color(0xFF101113), borderRadius: BorderRadius.circular(39.0)),
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 112.0,
                                          height: 26.0,
                                          decoration: BoxDecoration(color: const Color(0xFF08080A), borderRadius: BorderRadius.circular(999.0)),
                                          child: const SizedBox.shrink(),
                                        ),
                                        Container(
                                          height: 43.0,
                                          padding: const EdgeInsets.fromLTRB(21.0, 13.0, 21.0, 0.0),
                                          child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Flexible(child: Text(
                                                  "9:41",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                )),
                                          ],
                                        ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 10.0),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Strategies",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 28.0, fontWeight: FontWeight.w400, letterSpacing: -0.8, fontFamily: "Instrument Serif"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0),
                                                      child: const Text(
                                                      "Your focus plan for this week.",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 12.0, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  width: 36.0,
                                                  height: 36.0,
                                                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFD496), Color(0xFF8B4C31)]), boxShadow: [BoxShadow(color: Color(0xA6FFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 2.0)]),
                                                  child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Text(
                                                      "AG",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                              margin: EdgeInsets.zero,
                                              child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "24",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Mon",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "25",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Tue",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "26",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Wed",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "27",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Thu",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                                const SizedBox(width: 8.0),
                                                Flexible(child: Container(
                                                  width: 52.0,
                                                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 0.0),
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(17.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
                                                      child: const Text(
                                                      "28",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    const Text(
                                                      "Fri",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                  ],
                                                ),
                                                )),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              width: 110.0,
                                              height: 110.0,
                                              padding: const EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x14FCF9F1), Color(0x2EC5099C)]), border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                                                  color: const Color(0x1AFFFFFF),
                                                  child: const Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "TODAY’S STRATEGY",
                                                      style: TextStyle(color: Color(0xFFFF7AD8), fontSize: 9.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                ),
                                                Align(
                                                  alignment: Alignment.topCenter,
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 220.0),
                                                    child: Container(
                                                  margin: const EdgeInsets.fromLTRB(0.0, 11.0, 0.0, 6.0),
                                                  child: const Text(
                                                  "Invite one family before service.",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18.0, fontWeight: FontWeight.w700, height: 1.12, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment: Alignment.topCenter,
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 240.0),
                                                    child: Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Share the Family Worship Service with someone nearby and offer to meet them at the entrance.",
                                                  style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, height: 1.45, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Action Plan",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "Edit goals ›",
                                                    style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(12.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 38.0,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(color: const Color(0x1FEFD496), borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "✦",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17.0, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Pray for two invitees",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Set a 10-minute checkpoint today.",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      width: 23.0,
                                                      height: 23.0,
                                                      decoration: BoxDecoration(color: const Color(0x291F8A4C), border: Border.all(color: const Color(0x00000000), width: 1.5)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "✓",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 11.0, fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(12.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 38.0,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(color: const Color(0x1FEFD496), borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "⌁",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17.0, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Join department huddle",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Connect with your serving team.",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      width: 23.0,
                                                      height: 23.0,
                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 1.5)),
                                                      child: const SizedBox.shrink(),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.all(12.0),
                                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Container(
                                                      width: 38.0,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(color: const Color(0x1FEFD496), borderRadius: BorderRadius.circular(14.0)),
                                                      child: const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: [
                                                        Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(child: Text(
                                                          "↗",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17.0, fontFamily: "Instrument Sans"),
                                                        )),
                                                        ],
                                                      ),
                                                      ],
                                                    ),
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                          child: const Text(
                                                          "Share testimony after service",
                                                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsets.all(0.0),
                                                          child: const Text(
                                                          "Post in community or send to host.",
                                                          style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.0, height: 1.25, fontFamily: "Instrument Sans"),
                                                        ),
                                                        ),
                                                      ],
                                                    )),
                                                      const SizedBox(width: 10.0),
                                                      Expanded(child: Container(
                                                      width: 23.0,
                                                      height: 23.0,
                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 1.5)),
                                                      child: const SizedBox.shrink(),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
                                              child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(0.0),
                                                  child: const Text(
                                                  "Upcoming Service",
                                                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: -0.1, fontFamily: "Instrument Sans"),
                                                ),
                                                ),
                                                InkWell(
                                                  onTap: () { /* Launch # */ },
                                                  child: const Text(
                                                    "Open ›",
                                                    style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 11.0, fontFamily: "Instrument Sans"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(11.0),
                                              decoration: BoxDecoration(border: Border.all(color: const Color(0x00000000), width: 1.0)),
                                              child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 40.0,
                                                  height: 40.0,
                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0)),
                                                  child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(child: Text(
                                                      "⌚",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900, fontFamily: "Instrument Sans"),
                                                    )),
                                                    ],
                                                  ),
                                                  ],
                                                ),
                                                )),
                                                  const SizedBox(width: 10.0),
                                                  Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 3.0),
                                                      child: const Text(
                                                      "Family Worship Service",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.all(0.0),
                                                      child: const Text(
                                                      "Tonight • 8:00pm – 02:00am • His Glory Expression",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 10.5, height: 1.3, fontFamily: "Instrument Sans"),
                                                    ),
                                                    ),
                                                  ],
                                                )),
                                                  const SizedBox(width: 10.0),
                                                  Expanded(child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 7.0),
                                                  color: const Color(0x1F1F8A4C),
                                                  child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(child: Text(
                                                      "Live",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 9.0, fontWeight: FontWeight.w700, fontFamily: "Instrument Sans"),
                                                    )),
                                                  ],
                                                ),
                                                )),
                                                ],
                                              ),
                                              ],
                                            ),
                                            ),
                                          ],
                                        ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF)),
                                          child: const Text("Check in to service", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800, fontFamily: "Instrument Sans")),
                                        ),
                                        Container(
                                          height: 74.0,
                                          padding: const EdgeInsets.fromLTRB(22.0, 8.0, 22.0, 19.0),
                                          color: const Color(0xF00F1112),
                                          child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Home",
                                                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Events",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "People",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                              Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Container(
                                                  width: 19.0,
                                                  height: 19.0,
                                                  color: const Color(0xFFEEEEEE),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image, size: 32.0, color: Color(0xFF9E9E9E)),
                                                )),
                                                ],
                                              ),
                                                const SizedBox(height: 4.0),
                                                const Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: Text(
                                                      "Profile",
                                                      style: TextStyle(color: Color(0xFFA5ABAE), fontSize: 9.0, fontWeight: FontWeight.w600, fontFamily: "Instrument Sans"),
                                                    )),
                                                ],
                                              ),
                                              ],
                                            )),
                                            ],
                                          ),
                                          ],
                                        ),
                                        ),
                                      ],
                                    ),
                                    ),
                                ),
                              ],
                            )),
                            ],
                          ),
                          ],
                        ),
                      ],
                    ),
                    ),
                ),
      ),
    );
  }
}
