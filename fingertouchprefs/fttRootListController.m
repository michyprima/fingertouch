#include "fttRootListController.h"

@implementation fttRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

-(void)donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=65HU6MUS7E9GJ"]];
}

-(void)blog {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://micheleprimavera.eu"]];
}

@end
