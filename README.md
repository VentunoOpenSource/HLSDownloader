# HLSDownloader
HLS Subtitle Download iOS
The default media setup in the m3u8 get downloaded automatically by AVAssetDownloadTask

For instance </br>
> #EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT=YES,AUTOSELECT=YES,FORCED=NO,LANGUAGE="en",URI="subtitles_en.m3u8" </br>

This english subtile will be downloaded automatically by AVAssetDownloadTask and can be used in offline playback
