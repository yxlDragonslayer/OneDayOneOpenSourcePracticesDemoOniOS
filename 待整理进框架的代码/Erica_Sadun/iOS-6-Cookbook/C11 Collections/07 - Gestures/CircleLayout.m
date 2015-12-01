/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import "CircleLayout.h"

@implementation CircleLayout

- (void) prepareLayout
{
    [super prepareLayout];
    
    CGSize size = self.collectionView.frame.size;
    numberOfItems = [self.collectionView numberOfItemsInSection:0];
    centerPoint = CGPointMake(size.width / 2.0f, size.height / 2.0f);
    radius = MIN(size.width, size.height) / 3.0f;
}

// Fix the content size to the frame size
- (CGSize) collectionViewContentSize
{
    return self.collectionView.frame.size;
}

- (id) init
{
    if (!(self = [super init])) return nil;
    
    scale = 1.0f;
    rotation = 0.0f;
    currentRotation = 0.0f;
    
    return self;
}

- (void) rotateBy: (CGFloat)theta
{
    currentRotation = theta;
}

- (void) rotateTo: (CGFloat) theta
{
    rotation += theta;
    currentRotation = 0.0f;
}

- (void) scaleTo: (CGFloat) factor
{
    scale = factor;
}


// Calculate position for each item
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    CGFloat progress = (float) path.item / (float) numberOfItems;
    CGFloat theta = 2.0f * M_PI * progress;

    CGFloat scaledRadius = MIN(MAX(scale, 0.5f), 1.3f) * radius;
    CGFloat rotatedTheta = theta + rotation + currentRotation;
    
    CGFloat xPosition = centerPoint.x + scaledRadius * cos(rotatedTheta);
    CGFloat yPosition = centerPoint.y + scaledRadius * sin(rotatedTheta);
    attributes.size = [self itemSize];
    attributes.center = CGPointMake(xPosition, yPosition);
    return attributes;
}

// Calculate layouts
- (NSArray *) layoutAttributesForElementsInRect: (CGRect) rect
{
    NSMutableArray *attributes = [NSMutableArray array];
    for (NSInteger index = 0 ; index < numberOfItems; index++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForInsertedItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    attributes.alpha = 0.0;
    attributes.center = centerPoint;
    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDeletedItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    attributes.alpha = 0.0;
    attributes.center = centerPoint;
    attributes.transform3D = CATransform3DMakeScale(0.1, 0.1, 1.0);
    return attributes;
}
@end
