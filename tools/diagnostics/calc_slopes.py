# Calculate vertex positions for SlopeL and SlopeR on Path1_ResidentialCottage

# SlopeL:
# size = Vector3(5.32, 0.18, 6.8)
# pos = (-2.125, 1.6, 0.0)
# Basis:
# X: (0.7988708, -0.6015027, 0) in Godot col-major?
# Let's check Godot 4 Transform3D text format:
# Transform3D(xx, xy, xz, yx, yy, yz, zx, zy, zz, ox, oy, oz)
# In Godot docs:
# Transform3D(Vector3 x_axis, Vector3 y_axis, Vector3 z_axis, Vector3 origin)
# That means:
# x_axis = (xx, xy, xz)
# y_axis = (yx, yy, yz)
# z_axis = (zx, zy, zz)
# origin = (ox, oy, oz)

# Let's check:
# For SlopeL:
# Transform3D(0.7988708, 0.6015027, 0, -0.6015027, 0.7988708, 0, 0, 0, 1, -2.125, 1.6, 0)
# Here:
# x_axis = (0.7988708, 0.6015027, 0)
# y_axis = (-0.6015027, 0.7988708, 0)
# z_axis = (0, 0, 1)
# origin = (-2.125, 1.6, 0)

# For a BoxMesh of size (5.32, 0.18, 6.8):
# Local points: x in [-2.66, +2.66], y in [-0.09, +0.09], z in [-3.4, +3.4]

# For SlopeL:
# At local x = -2.66 (leftmost):
# Point = origin + (-2.66) * x_axis
# Point.x = -2.125 - 2.66 * 0.79887 = -2.125 - 2.125 = -4.25
# Point.y = 1.6 - 2.66 * 0.60150 = 1.6 - 1.600 = 0.00
# At local x = +2.66 (rightmost):
# Point.x = -2.125 + 2.66 * 0.79887 = -2.125 + 2.125 = 0.00
# Point.y = 1.6 + 2.66 * 0.60150 = 1.6 + 1.600 = 3.20
# So for SlopeL:
# Left edge (eaves): x = -4.25, y = 0.00
# Right edge (ridge): x = 0.00, y = 3.20
# SlopeL goes from eave at (-4.25, 0) up to ridge at (0, 3.20).
print("SlopeL: Left eave at (-4.25, 0.00), Ridge at (0.00, 3.20)")

# NOW FOR SlopeR:
# Transform3D(0.7988708, -0.6015027, 0, 0.6015027, 0.7988708, 0, 0, 0, 1, 2.125, 1.6, 0)
# Here:
# x_axis = (0.7988708, -0.6015027, 0)
# y_axis = (0.6015027, 0.7988708, 0)
# z_axis = (0, 0, 1)
# origin = (2.125, 1.6, 0)

# At local x = -2.66:
# Point.x = 2.125 - 2.66 * 0.79887 = 2.125 - 2.125 = 0.00
# Point.y = 1.6 - 2.66 * (-0.60150) = 1.6 + 1.600 = 3.20
# At local x = +2.66:
# Point.x = 2.125 + 2.66 * 0.79887 = 2.125 + 2.125 = 4.25
# Point.y = 1.6 + 2.66 * (-0.60150) = 1.6 - 1.600 = 0.00
print("SlopeR: Ridge at (0.00, 3.20), Right eave at (4.25, 0.00)")
