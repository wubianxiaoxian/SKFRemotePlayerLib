//
//  SKFAudioDownLoader.m
//  SKFDownLoadListern
//
//  Created by 孙凯峰 on 2017/4/1.
//  Copyright © 2017年 孙凯峰. All rights reserved.
//

#import "SKFAudioDownLoader.h"
#import "SKFAudioFileTool.h"
@interface SKFAudioDownLoader ()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) NSURL *url;





@end
@implementation SKFAudioDownLoader
- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}


- (void)downLoadWithURL: (NSURL *)url offset: (long long)offset {
    
    self.url = url;
    self.offset = offset;
    
    
    [self cancel];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
    
}


- (void)cancel {
    
    [self.session invalidateAndCancel];
    self.session = nil;
    
    // 清理缓存
    [SKFAudioFileTool removeTmpFileWithURL:self.url];
    
    // 重置数据
    self.loadedSize = 0;
    
    
}




#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    NSHTTPURLResponse *httpResponse =  (NSHTTPURLResponse *)response;
    
    self.totalSize = [[[httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
    self.contentType = httpResponse.MIMEType;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[SKFAudioFileTool tmpPathWithURL:self.url] append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    
    if ([self.delegate respondsToSelector:@selector(downLoaderLoading)]) {
        [self.delegate downLoaderLoading];
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error == nil) {
        // 判断, 本地下载的大小, 是否等于文件的总大小
        if ([SKFAudioFileTool tmpFileSizeWithURL:self.url] == self.totalSize)
        {
            [SKFAudioFileTool moveTmpPathToCachePath:self.url];
        }
    }
    
    
}


@end
