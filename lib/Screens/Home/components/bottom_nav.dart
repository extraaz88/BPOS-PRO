import 'package:flutter/material.dart';
import 'package:mobile_pos/constant.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != widget.currentIndex) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kWhite,
            kWhite.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
          BoxShadow(
            color: kMainColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(
          color: kMainColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: kMainColor,
          unselectedItemColor: kGreyTextColor.withOpacity(0.7),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
          currentIndex: widget.currentIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                index: 0,
                activeIcon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                index: 1,
                activeIcon: Icons.dashboard_rounded,
                inactiveIcon: Icons.dashboard_outlined,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                index: 2,
                activeIcon: Icons.analytics_rounded,
                inactiveIcon: Icons.analytics_outlined,
              ),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                index: 3,
                activeIcon: Icons.settings_rounded,
                inactiveIcon: Icons.settings_outlined,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final isSelected = widget.currentIndex == index;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _scaleAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kMainColor.withOpacity(0.15),
                        kMainColor.withOpacity(0.08),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: kMainColor.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background glow effect for selected item
                if (isSelected)
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              kMainColor
                                  .withOpacity(0.2 * _fadeAnimation.value),
                              kMainColor
                                  .withOpacity(0.05 * _fadeAnimation.value),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                // Icon
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: isSelected ? 26 : 24,
                  color:
                      isSelected ? kMainColor : kGreyTextColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}