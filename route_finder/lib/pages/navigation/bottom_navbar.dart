import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacings.lg,
            horizontal: AppSpacings.lg,
          ),
          child: SizedBox(
            height: 60,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / 4;
                return Stack(
                  children: [
                    // Sliding Background
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      left: widget.selectedIndex * itemWidth,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Center(
                        child: Container(
                          width: itemWidth - 10, // Slight padding
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColor.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Nav Items
                    Row(
                      children: [
                        _NavItem(
                          icon: LucideIcons.house,
                          label: "Home",
                          isSelected: widget.selectedIndex == 0,
                          onTap: () => widget.onTap(0),
                          width: itemWidth,
                        ),
                        _NavItem(
                          icon: LucideIcons.compass,
                          label: "Explore",
                          isSelected: widget.selectedIndex == 1,
                          onTap: () => widget.onTap(1),
                          width: itemWidth,
                        ),
                        _NavItem(
                          icon: LucideIcons.route300,
                          label: "Routes",
                          isSelected: widget.selectedIndex == 2,
                          onTap: () => widget.onTap(2),
                          width: itemWidth,
                        ),
                        _NavItem(
                          icon: LucideIcons.user,
                          label: "Profile",
                          isSelected: widget.selectedIndex == 3,
                          onTap: () => widget.onTap(3),
                          width: itemWidth,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                color: isSelected ? AppColor.primary : AppColor.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacings.sm),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? AppColor.primary : AppColor.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Nunito',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
