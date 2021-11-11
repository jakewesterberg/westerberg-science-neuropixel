pic = 1;
mov = 2;

ML_Benchmark = true;
varargout{1} = cell(2,2);

for m=1:2
    dashboard(1,sprintf('Testing the screen flipping latency... (Pass %d/2)',m));
    
    ML_BenchmarkSampleCount = 1;
    fliptime = toggleobject(pic,'status','on');
    idle(1000);
    toggleobject(pic,'status','off');
    ML_BenchmarkSample(1) = fliptime;
    varargout{1}{m,1} = ML_BenchmarkSample(1:ML_BenchmarkSampleCount);

    ML_BenchmarkSampleCount = 1;
    ML_BenchmarkFrameCount = 1;
    fliptime = toggleobject(mov,'status','on');
    idle(1000);
    toggleobject(mov,'status','off');
    ML_BenchmarkSample(1) = fliptime;
    ML_BenchmarkFrame(1) = fliptime;
    varargout{1}{m,2} = { ML_BenchmarkSample(1:ML_BenchmarkSampleCount), ML_BenchmarkFrame(1:ML_BenchmarkFrameCount) };
    rewind_movie(mov);
    
    drawnow;
end
