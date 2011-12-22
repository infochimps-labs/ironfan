function FindProxyForURL(url, host) {
  if ((shExpMatch(host, "*ec2*.amazonaws.com"      )) ||
      (shExpMatch(host, "*ec2.internal*"           )) ||
      (shExpMatch(host, "*compute-*.amazonaws.com" )) ||
      (shExpMatch(host, "*compute-*.internal*"     )) ||
      (shExpMatch(host, "*domu*.internal*"         )) ||
      (shExpMatch(host, "10.*"                     )) 
      ) {
    return "SOCKS5 localhost:6666";
  }
  return "DIRECT";
}
