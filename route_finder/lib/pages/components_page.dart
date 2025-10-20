// lib/pages/components_page.dart
import 'package:flutter/material.dart';
import 'package:route_finder/logic/models.dart';
import '../components/components.dart';

class ComponentsPage extends StatefulWidget {
  const ComponentsPage({Key? key}) : super(key: key);

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  double _radius = 3.0;
  final List<String> _chips = ['arte', 'comida'];
  int _rating = 4;
  List<String> suggestions = ['arte', 'história', 'comida', 'natureza', 'compras'];
  @override
  Widget build(BuildContext context) {
    final markers = [
      MapMarker(id: 'm1', coord: const Coordinate(lat: 40.6411, lng: -8.6520), label: 'Café'),
      MapMarker(id: 'm2', coord: const Coordinate(lat: 40.6420, lng: -8.6510), label: 'Museu'),
    ];
    final poly = [
      const Coordinate(lat: 40.6405, lng: -8.6538),
      const Coordinate(lat: 40.6411, lng: -8.6520),
      const Coordinate(lat: 40.6420, lng: -8.6510),
      const Coordinate(lat: 40.6430, lng: -8.6515),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Components demo'),
        backgroundColor: kPrimary,
      ),
      floatingActionButton: AppFAB(
        onPressed: () => AppToast.show(context, 'FAB pressed'),
        child: const Icon(Icons.explore),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Buttons', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AppButton(label: 'Primária', onTap: () => AppToast.show(context, 'Primária')),
                AppButton(label: 'Ghost', variant: AppButtonVariant.ghost, onTap: () => AppToast.show(context, 'Ghost')),
                AppButton(label: 'Outline', variant: AppButtonVariant.outline, onTap: () => AppToast.show(context, 'Outline')),
                AppButton(label: 'Perigo', variant: AppButtonVariant.danger, onTap: () => AppToast.show(context, 'Danger')),
                AppButton(label: 'Loading', isLoading: true, onTap: () {}),
              ],
            ),

            const SizedBox(height: 18),
            const Text('Search + Chips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            SearchChipsBar(
              initialChips: _chips,
              suggestions: suggestions,
              onChipAdded: (s) => AppToast.show(context, 'Chip added: $s'),
            ),

            const SizedBox(height: 18),
            const Text('Radius slider', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            RadiusSlider(
              valueKm: _radius,
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 8),
            Text('Raio actual: ${_radius.toStringAsFixed(1)} km'),

            // const SizedBox(height: 18),
            // const Text('Map mock (polyline + markers)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            // const SizedBox(height: 8),
            // SizedBox(
            //   height: 220,
            //   child: MockMapView(
            //     polyline: poly,
            //     markers: markers,
            //     onMarkerTap: (id) => AppToast.show(context, 'Marker tapped: $id'),
            //   ),
            // ),

            const SizedBox(height: 18),
            const Text('POI Card', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            POICard(
              title: 'Museu Local',
              subtitle: 'Rua Principal, 12',
              imageUrl: 'https://images.unsplash.com/photo-1528747008803-1c09a7e3a1b6',
              rating: 4.3,
              tags: const ['museum', 'arte'],
              onTap: () => AppToast.show(context, 'Open POI'),
              openNow: false,
            ),

            const SizedBox(height: 18),
            const Text('Rating Stars', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            RatingStars(initial: _rating, onChanged: (v) => setState(() => _rating = v)),

            const SizedBox(height: 18),
            const Text('Image Carousel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            ImageCarousel(images: [
              'https://images.unsplash.com/photo-1543353071-087092ec393e',
              'https://images.unsplash.com/photo-1528747008803-1c09a7e3a1b6',
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836'
            ], height: 160),

            const SizedBox(height: 18),
            const Text('Skeletons', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(child: SkeletonBox(height: 60)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 60)),
              ],
            ),

            const SizedBox(height: 18),
            const Text('Bottom sheet & dialog', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: [
                AppButton(
                  fullWidth: false,
                  label: 'Abrir bottom sheet',
                  variant: AppButtonVariant.ghost,
                  onTap: () => showAppBottomSheet(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 12),
                        const Text('Este é um bottom sheet de exemplo'),
                        const SizedBox(height: 12),
                        AppButton(label: 'Fechar', onTap: () => Navigator.of(context).pop()),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  fullWidth: false,
                  label: 'Abrir diálogo',
                  variant: AppButtonVariant.outline,
                  onTap: () => showAppDialog(
                    context: context,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Diálogo de exemplo'),
                      const SizedBox(height: 12),
                      AppButton(label: 'OK', onTap: () => Navigator.of(context).pop()),
                    ]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}