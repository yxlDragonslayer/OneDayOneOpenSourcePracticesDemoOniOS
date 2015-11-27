//
//  MIT License
//
//  Copyright (c) 2013 Bob McCune http://bobmccune.com/
//  Copyright (c) 2013 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//

#import "THBasicComposition.h"

@interface THBasicComposition ()
@property (nonatomic, strong) AVComposition *composition;
@property (nonatomic, strong) AVVideoComposition *videoComposition;
@property (nonatomic, strong) AVAudioMix *audioMix;
@property (nonatomic, strong) CALayer *titleLayer;
@end

@implementation THBasicComposition

+ (id)compositionWithComposition:(AVComposition *)composition {
	return [[self alloc] initWithComposition:composition];
}

- (id)initWithComposition:(AVComposition *)composition {
	self = [super init];
	if (self) {
		_composition = composition;
	}
	return self;
}

- (AVPlayerItem *)makePlayable {
	return [AVPlayerItem playerItemWithAsset:[self.composition copy]];
}

- (AVAssetExportSession *)makeExportable {
	return [AVAssetExportSession exportSessionWithAsset:[self.composition copy] presetName:AVAssetExportPresetHighestQuality];
}

@end
