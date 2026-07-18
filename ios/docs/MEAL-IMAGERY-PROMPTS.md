# Meal Imagery Prompt Kit

Food photography for the meal-prep cards and meal detail screens. Same operating
model as the exercise clips: generate in Higgsfield, drop into `Assets.xcassets`
named **`meal.<foodID>`** (e.g. `meal.chicken-breast`), and the UI picks each one
up automatically — missing images fall back to the gradient placeholder.

## Locked style (prepend to every prompt)

> Professional food photography, single serving of {SUBJECT} on a small matte
> ceramic plate in warm off-white, centered, shot from a 45-degree angle, soft
> diffused daylight from the left, gentle shadow, seamless light studio
> backdrop (#F6F6F4), minimal micro-greens garnish, crisp focus, high-end
> editorial minimalism, square 1:1, no hands, no text, no props beyond the plate.

Beverages swap the plate line for: "in a simple clear glass, centered".
Raw snack items (nuts, chocolate) swap for: "in a small shallow ceramic bowl".

## Subjects (filename → subject)

| Asset name | Subject |
|---|---|
| `meal.chicken-breast` | Chicken breast, grilled |
| `meal.chicken-thigh` | Chicken thigh, roasted |
| `meal.salmon` | Salmon fillet, baked |
| `meal.tuna-canned` | Tuna, canned in water |
| `meal.ground-beef` | Ground beef 85/15, cooked |
| `meal.steak-sirloin` | Sirloin steak, grilled |
| `meal.pork-chop` | Pork chop, grilled |
| `meal.turkey-breast` | Turkey breast, roasted |
| `meal.egg` | Egg, large |
| `meal.egg-white` | Egg white |
| `meal.shrimp` | Shrimp, cooked |
| `meal.tofu-firm` | Tofu, firm |
| `meal.tempeh` | Tempeh |
| `meal.whey-scoop` | Whey protein powder |
| `meal.brown-rice` | Brown rice, cooked |
| `meal.white-rice` | White rice, cooked |
| `meal.quinoa` | Quinoa, cooked |
| `meal.oatmeal` | Oatmeal, cooked with water |
| `meal.pasta` | Pasta, cooked |
| `meal.bread-whole-wheat` | Whole wheat bread |
| `meal.bread-white` | White bread |
| `meal.bagel` | Bagel, plain |
| `meal.tortilla-flour` | Flour tortilla |
| `meal.sweet-potato` | Sweet potato, baked |
| `meal.potato-baked` | Potato, baked with skin |
| `meal.banana` | Banana, medium |
| `meal.apple` | Apple, medium |
| `meal.orange` | Orange, medium |
| `meal.blueberries` | Blueberries |
| `meal.strawberries` | Strawberries |
| `meal.grapes` | Grapes |
| `meal.avocado` | Avocado |
| `meal.mango` | Mango, sliced |
| `meal.watermelon` | Watermelon, diced |
| `meal.broccoli` | Broccoli, steamed |
| `meal.spinach` | Spinach, raw |
| `meal.carrots` | Carrots, raw |
| `meal.bell-pepper` | Bell pepper, raw |
| `meal.cucumber` | Cucumber, sliced |
| `meal.tomato` | Tomato, medium |
| `meal.mixed-salad` | Mixed green salad, plain |
| `meal.green-beans` | Green beans, steamed |
| `meal.black-beans` | Black beans, cooked |
| `meal.chickpeas` | Chickpeas, cooked |
| `meal.lentils` | Lentils, cooked |
| `meal.almonds` | Almonds |
| `meal.peanut-butter` | Peanut butter |
| `meal.walnuts` | Walnuts |
| `meal.hummus` | Hummus |
| `meal.greek-yogurt` | Greek yogurt, plain nonfat |
| `meal.cottage-cheese` | Cottage cheese, 2% |
| `meal.cheddar` | Cheddar cheese |
| `meal.milk-2pct` | Milk, 2% |
| `meal.milk-almond` | Almond milk, unsweetened |
| `meal.mozzarella` | Mozzarella, part-skim |
| `meal.olive-oil` | Olive oil |
| `meal.butter` | Butter |
| `meal.mayo` | Mayonnaise |
| `meal.ketchup` | Ketchup |
| `meal.dark-chocolate` | Dark chocolate, 70-85% |
| `meal.potato-chips` | Potato chips |
| `meal.protein-bar` | Protein bar |
| `meal.granola` | Granola |
| `meal.orange-juice` | Orange juice |
| `meal.cola` | Cola |
| `meal.latte` | Latte with 2% milk |
| `meal.cheese-pizza` | Cheese pizza |
| `meal.hamburger` | Hamburger, single patty |
| `meal.french-fries` | French fries |
| `meal.burrito-chicken` | Chicken burrito |
| `meal.sushi-roll` | California roll |

## Workflow

1. Batch-generate with the locked style + each subject line (71 total).
2. Review for consistency (same plate, same light, same backdrop) — regenerate outliers.
3. Downscale to ~800×800 JPEG (quality 0.8) to keep the bundle lean (~70 × ~80 KB ≈ 6 MB).
4. Drag into `Assets.xcassets`, rename each imageset to the asset name above, build, push.

The meal detail hero shows the image of the first ingredient that has one, so
partial batches are fine — ship the staples (proteins, grains) first.
